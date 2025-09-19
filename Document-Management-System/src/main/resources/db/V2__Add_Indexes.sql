-- Performance indexes for documents
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_department ON documents(department_id);
CREATE INDEX idx_documents_created_by ON documents(created_by);
CREATE INDEX idx_documents_created_at ON documents(created_at DESC);
CREATE INDEX idx_documents_uuid ON documents(uuid);

-- Full-text search indexes
CREATE INDEX idx_documents_fulltext ON documents
USING GIN (to_tsvector('english', title || ' ' || COALESCE(description, '') || ' ' || COALESCE(content, '')));

-- Search with weights (title more important than content)
CREATE INDEX idx_documents_weighted_search ON documents
USING GIN (
    setweight(to_tsvector('english', title), 'A') ||
    setweight(to_tsvector('english', COALESCE(description, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(content, '')), 'C')
);

-- Tags search
CREATE INDEX idx_documents_tags ON documents USING GIN(tags);

-- Metadata search
CREATE INDEX idx_documents_metadata ON documents USING GIN(metadata);

-- Classification and security
CREATE INDEX idx_documents_classification ON documents(classification);

-- Version control
CREATE INDEX idx_documents_version ON documents(parent_version_id, version_number);
CREATE INDEX idx_documents_current ON documents(is_current_version) WHERE is_current_version = TRUE;

-- Workflow indexes
CREATE INDEX idx_workflow_instances_state ON workflow_instances(current_state);
CREATE INDEX idx_workflow_instances_document ON workflow_instances(document_id);
CREATE INDEX idx_workflow_instances_assigned ON workflow_instances(assigned_to);
CREATE INDEX idx_workflow_instances_due_date ON workflow_instances(due_date) WHERE due_date IS NOT NULL;

-- Approval tasks indexes
CREATE INDEX idx_approval_tasks_assigned ON approval_tasks(assigned_to, status);
CREATE INDEX idx_approval_tasks_workflow ON approval_tasks(workflow_instance_id);
CREATE INDEX idx_approval_tasks_due_date ON approval_tasks(due_date) WHERE status = 'PENDING';

-- User and permission indexes
CREATE INDEX idx_users_department ON users(department_id);
CREATE INDEX idx_users_manager ON users(manager_id);
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = TRUE;

CREATE INDEX idx_document_permissions_doc ON document_permissions(document_id);
CREATE INDEX idx_document_permissions_user ON document_permissions(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_document_permissions_dept ON document_permissions(department_id) WHERE department_id IS NOT NULL;
CREATE INDEX idx_document_permissions_active ON document_permissions(is_active) WHERE is_active = TRUE;

-- Audit and notification indexes
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(performed_by);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);

CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- File chunks indexes
CREATE INDEX idx_file_chunks_upload ON file_chunks(upload_id);
CREATE INDEX idx_file_chunks_created ON file_chunks(created_at);
