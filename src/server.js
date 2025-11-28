import express from 'express';
import fileUpload from 'express-fileupload';
import cors from 'cors';
import { join, dirname, extname } from 'path';
import { fileURLToPath } from 'url';
import { existsSync, mkdirSync } from 'fs';
import db from './db.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = process.env.PORT || 3000;

// Directories
const publicDir = join(__dirname, '..', 'public');
const uploadsDir = join(__dirname, '..', 'uploads');

// Create directories if they don't exist
[publicDir, uploadsDir].forEach(dir => {
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
});

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(fileUpload({
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  abortOnLimit: true
}));

// Serve static files
app.use(express.static(publicDir));
app.use('/uploads', express.static(uploadsDir));

// ====================
// API ENDPOINTS
// ====================

// GET /api/rules - List all rules
app.get('/api/rules', (req, res) => {
  try {
    const rules = db.prepare(`
      SELECT 
        r.id,
        r.title,
        r.description,
        r.filename,
        r.original_filename,
        r.file_size,
        r.created_at,
        GROUP_CONCAT(t.name) as tags
      FROM rules r
      LEFT JOIN rule_tags rt ON r.id = rt.rule_id
      LEFT JOIN tags t ON rt.tag_id = t.id
      GROUP BY r.id
      ORDER BY r.created_at DESC
    `).all();

    // Process tags as array
    const processedRules = rules.map(rule => ({
      ...rule,
      tags: rule.tags ? rule.tags.split(',') : []
    }));

    res.json(processedRules);
  } catch (error) {
    console.error('Error fetching rules:', error);
    res.status(500).json({ error: 'Error fetching rules' });
  }
});

// GET /api/rules/search?q=term - Search rules by term
app.get('/api/rules/search', (req, res) => {
  try {
    const query = req.query.q || '';
    
    const rules = db.prepare(`
      SELECT DISTINCT
        r.id,
        r.title,
        r.description,
        r.filename,
        r.original_filename,
        r.file_size,
        r.created_at,
        GROUP_CONCAT(DISTINCT t.name) as tags
      FROM rules r
      LEFT JOIN rule_tags rt ON r.id = rt.rule_id
      LEFT JOIN tags t ON rt.tag_id = t.id
      WHERE r.title LIKE ? OR r.description LIKE ? OR t.name LIKE ?
      GROUP BY r.id
      ORDER BY r.created_at DESC
    `).all(`%${query}%`, `%${query}%`, `%${query}%`);

    const processedRules = rules.map(rule => ({
      ...rule,
      tags: rule.tags ? rule.tags.split(',') : []
    }));

    res.json(processedRules);
  } catch (error) {
    console.error('Error searching rules:', error);
    res.status(500).json({ error: 'Error searching rules' });
  }
});

// GET /api/rules/tag/:tag - Filter rules by tag
app.get('/api/rules/tag/:tag', (req, res) => {
  try {
    const tag = req.params.tag;
    
    const rules = db.prepare(`
      SELECT 
        r.id,
        r.title,
        r.description,
        r.filename,
        r.original_filename,
        r.file_size,
        r.created_at,
        GROUP_CONCAT(t.name) as tags
      FROM rules r
      INNER JOIN rule_tags rt ON r.id = rt.rule_id
      INNER JOIN tags t ON rt.tag_id = t.id
      WHERE r.id IN (
        SELECT DISTINCT r2.id
        FROM rules r2
        INNER JOIN rule_tags rt2 ON r2.id = rt2.rule_id
        INNER JOIN tags t2 ON rt2.tag_id = t2.id
        WHERE t2.name = ?
      )
      GROUP BY r.id
      ORDER BY r.created_at DESC
    `).all(tag);

    const processedRules = rules.map(rule => ({
      ...rule,
      tags: rule.tags ? rule.tags.split(',') : []
    }));

    res.json(processedRules);
  } catch (error) {
    console.error('Error fetching rules by tag:', error);
    res.status(500).json({ error: 'Error fetching rules by tag' });
  }
});

// GET /api/tags - List all tags
app.get('/api/tags', (req, res) => {
  try {
    const tags = db.prepare(`
      SELECT 
        t.id,
        t.name,
        COUNT(rt.rule_id) as count
      FROM tags t
      LEFT JOIN rule_tags rt ON t.id = rt.tag_id
      GROUP BY t.id
      ORDER BY count DESC, t.name ASC
    `).all();

    res.json(tags);
  } catch (error) {
    console.error('Error fetching tags:', error);
    res.status(500).json({ error: 'Error fetching tags' });
  }
});

// POST /api/rules/upload - Upload new rule
app.post('/api/rules/upload', (req, res) => {
  try {
    if (!req.files || !req.files.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const file = req.files.file;
    const { title, description, tags } = req.body;

    // Validations
    if (!title) {
      return res.status(400).json({ error: 'Title is required' });
    }

    // Validate file extension
    const allowedExtensions = ['.cursorrules', '.md', '.txt'];
    const fileExt = extname(file.name).toLowerCase();
    
    if (!allowedExtensions.includes(fileExt) && file.name !== '.cursorrules') {
      return res.status(400).json({ 
        error: 'Only .cursorrules, .md or .txt files are allowed' 
      });
    }

    // Generate unique filename
    const timestamp = Date.now();
    const filename = `${timestamp}-${file.name}`;
    const filepath = join(uploadsDir, filename);

    // Move file to uploads directory
    file.mv(filepath, (err) => {
      if (err) {
        console.error('Error saving file:', err);
        return res.status(500).json({ error: 'Error saving file' });
      }

      // Insert into database
      const insertRule = db.prepare(`
        INSERT INTO rules (title, description, filename, original_filename, file_size)
        VALUES (?, ?, ?, ?, ?)
      `);

      const result = insertRule.run(
        title,
        description || null,
        filename,
        file.name,
        file.size
      );

      const ruleId = result.lastInsertRowid;

      // Process tags
      if (tags) {
        const tagsList = typeof tags === 'string' ? tags.split(',') : tags;
        
        tagsList.forEach(tagName => {
          const trimmedTag = tagName.trim();
          if (trimmedTag) {
            // Insert tag if it doesn't exist
            const insertTag = db.prepare('INSERT OR IGNORE INTO tags (name) VALUES (?)');
            insertTag.run(trimmedTag);

            // Get tag ID
            const tag = db.prepare('SELECT id FROM tags WHERE name = ?').get(trimmedTag);

            // Associate tag with rule
            if (tag) {
              const insertRuleTag = db.prepare('INSERT INTO rule_tags (rule_id, tag_id) VALUES (?, ?)');
              insertRuleTag.run(ruleId, tag.id);
            }
          }
        });
      }

      res.json({
        success: true,
        message: 'Rule uploaded successfully',
        ruleId
      });
    });
  } catch (error) {
    console.error('Error uploading:', error);
    res.status(500).json({ error: 'Error uploading' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log('');
  console.log('🚀 Server started successfully!');
  console.log('');
  console.log(`📍 URL: http://localhost:${PORT}`);
  console.log(`📁 Public: ${publicDir}`);
  console.log(`📦 Uploads: ${uploadsDir}`);
  console.log('');
  console.log('Press Ctrl+C to stop the server');
  console.log('');
});

// Error handling
process.on('SIGINT', () => {
  console.log('\n👋 Closing server...');
  db.close();
  process.exit(0);
});

