import db from './db.js';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { existsSync, mkdirSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const uploadsDir = join(__dirname, '..', 'uploads');

// Create uploads directory if it doesn't exist
if (!existsSync(uploadsDir)) {
  mkdirSync(uploadsDir, { recursive: true });
}

console.log('🗄️  Initializing database...');

// Create rules table
db.exec(`
  CREATE TABLE IF NOT EXISTS rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_size INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`);

// Create tags table
db.exec(`
  CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`);

// Create relationship table between rules and tags
db.exec(`
  CREATE TABLE IF NOT EXISTS rule_tags (
    rule_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (rule_id, tag_id),
    FOREIGN KEY (rule_id) REFERENCES rules(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
  )
`);

// Insert default tags if they don't exist
const insertTag = db.prepare('INSERT OR IGNORE INTO tags (name) VALUES (?)');

const defaultTags = [
  'Frontend',
  'Backend',
  'Database',
  'React',
  'Vue',
  'Angular',
  'Node.js',
  'Python',
  'TypeScript',
  'JavaScript',
  'API',
  'Performance',
  'Security',
  'Testing',
  'DevOps'
];

defaultTags.forEach(tag => insertTag.run(tag));

console.log('✅ Database initialized successfully!');
console.log(`📦 Tables created: rules, tags, rule_tags`);
console.log(`🏷️  ${defaultTags.length} default tags inserted`);
console.log('');

// Show statistics
const rulesCount = db.prepare('SELECT COUNT(*) as count FROM rules').get();
const tagsCount = db.prepare('SELECT COUNT(*) as count FROM tags').get();

console.log(`📊 Statistics:`);
console.log(`   Rules: ${rulesCount.count}`);
console.log(`   Tags: ${tagsCount.count}`);

db.close();

