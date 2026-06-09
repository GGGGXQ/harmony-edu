-- 1. 给 chat_message 加临时列，记录旧 qa_id
ALTER TABLE chat_message ADD COLUMN temp_qa_id VARCHAR(36);

-- 2. 迁移 user 消息
INSERT INTO chat_message (id, session_id, role, content, created_at, temp_qa_id)
SELECT UUID(), sm.session_id, 'user', h.question, h.created_at, h.id
FROM qa_history h
JOIN session_qa sm ON sm.qa_id = h.id;

-- 3. 迁移 assistant 消息
INSERT INTO chat_message (id, session_id, role, content, created_at, temp_qa_id)
SELECT UUID(), sm.session_id, 'assistant', h.answer, h.created_at, h.id
FROM qa_history h
JOIN session_qa sm ON sm.qa_id = h.id;

-- 4. 更新 qa_source 关联到新的 assistant 消息
UPDATE qa_source s
JOIN chat_message m ON m.temp_qa_id = s.qa_id AND m.role = 'assistant'
SET s.message_id = m.id;

-- 5. 清理
ALTER TABLE chat_message DROP COLUMN temp_qa_id;
DROP TABLE IF EXISTS session_qa;
DROP TABLE IF EXISTS qa_history;
ALTER TABLE qa_source DROP COLUMN qa_id;
