-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create enums
CREATE TYPE user_role AS ENUM ('ADMIN', 'MANAGER', 'EMPLOYEE', 'VIEWER');
CREATE TYPE document_status AS ENUM ('DRAFT', 'PENDING_REVIEW', 'IN_REVIEW', 'APPROVED', 'REJECTED', 'ARCHIVED');
CREATE TYPE workflow_state AS ENUM ('CREATED', 'SUBMITTED', 'UNDER_REVIEW', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'COMPLETED', 'CANCELLED');
CREATE TYPE workflow_event AS ENUM ('SUBMIT', 'START_REVIEW', 'APPROVE', 'REJECT', 'REQUEST_CHANGES', 'RESUBMIT', 'COMPLETE', 'CANCEL');
CREATE TYPE permission_type AS ENUM ('READ', 'WRITE', 'DELETE', 'APPROVE', 'ADMIN');
CREATE TYPE audit_operation AS ENUM ('CREATE', 'UPDATE', 'DELETE', 'VIEW', 'DOWNLOAD', 'APPROVE', 'REJECT');

-- Departments table
CREATE TABLE departments (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id BIGINT REFERENCES departments(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users table
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role user_role NOT NULL DEFAULT 'EMPLOYEE',
    department_id BIGINT NOT NULL REFERENCES departments(id),
    manager_id BIGINT REFERENCES users(id),
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Documents table
CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content TEXT, -- For searchable text content
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    checksum VARCHAR(64), -- SHA-256 hash
    status document_status DEFAULT 'DRAFT',
    classification VARCHAR(50), -- PUBLIC, INTERNAL, CONFIDENTIAL, SECRET
    tags TEXT[], -- Array of tags
    metadata JSONB, -- Flexible metadata storage
    version_number INTEGER DEFAULT 1,
    parent_version_id BIGINT REFERENCES documents(id),
    is_current_version BOOLEAN DEFAULT TRUE,
    created_by BIGINT NOT NULL REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    department_id BIGINT NOT NULL REFERENCES departments(id),
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Document permissions table
CREATE TABLE document_permissions (
    id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES users(id),
    department_id BIGINT REFERENCES departments(id),
    permission_type permission_type NOT NULL,
    granted_by BIGINT NOT NULL REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_user_or_dept CHECK ((user_id IS NOT NULL) OR (department_id IS NOT NULL))
);

-- Workflow templates table
CREATE TABLE workflow_templates (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    department_id BIGINT REFERENCES departments(id),
    configuration JSONB NOT NULL, -- Workflow steps and rules
    is_active BOOLEAN DEFAULT TRUE,
    created_by BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Workflow instances table
CREATE TABLE workflow_instances (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    document_id BIGINT NOT NULL REFERENCES documents(id),
    template_id BIGINT NOT NULL REFERENCES workflow_templates(id),
    current_state workflow_state DEFAULT 'CREATED',
    priority INTEGER DEFAULT 1, -- 1=Low, 2=Normal, 3=High, 4=Critical
    due_date TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    started_by BIGINT NOT NULL REFERENCES users(id),
    assigned_to BIGINT REFERENCES users(id),
    context JSONB, -- Dynamic workflow data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Approval tasks table
CREATE TABLE approval_tasks (
    id BIGSERIAL PRIMARY KEY,
    workflow_instance_id BIGINT NOT NULL REFERENCES workflow_instances(id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL,
    step_name VARCHAR(100) NOT NULL,
    assigned_to BIGINT NOT NULL REFERENCES users(id),
    delegated_to BIGINT REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED, DELEGATED
    comments TEXT,
    decision_date TIMESTAMP,
    due_date TIMESTAMP,
    is_mandatory BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit log table
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT NOT NULL,
    operation audit_operation NOT NULL,
    old_values JSONB,
    new_values JSONB,
    performed_by BIGINT NOT NULL REFERENCES users(id),
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications table
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- INFO, WARNING, ERROR, SUCCESS
    related_entity_type VARCHAR(50),
    related_entity_id BIGINT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- File chunks table (for resumable uploads)
CREATE TABLE file_chunks (
    id BIGSERIAL PRIMARY KEY,
    upload_id UUID NOT NULL,
    chunk_number INTEGER NOT NULL,
    chunk_size BIGINT NOT NULL,
    chunk_hash VARCHAR(64) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    uploaded_by BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(upload_id, chunk_number)
);
