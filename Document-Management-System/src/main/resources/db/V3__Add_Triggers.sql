-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_departments_updated_at BEFORE UPDATE ON departments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workflow_instances_updated_at BEFORE UPDATE ON workflow_instances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    audit_user_id BIGINT;
BEGIN
    -- Get user ID from current session (you'll set this in your application)
    audit_user_id := COALESCE(current_setting('app.current_user_id', true)::BIGINT, 1);

    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (entity_type, entity_id, operation, old_values, performed_by)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD), audit_user_id);
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (entity_type, entity_id, operation, old_values, new_values, performed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), audit_user_id);
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (entity_type, entity_id, operation, new_values, performed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'CREATE', to_jsonb(NEW), audit_user_id);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Audit triggers for critical tables
CREATE TRIGGER audit_documents_trigger
    AFTER INSERT OR UPDATE OR DELETE ON documents
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_workflow_instances_trigger
    AFTER INSERT OR UPDATE OR DELETE ON workflow_instances
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_approval_tasks_trigger
    AFTER INSERT OR UPDATE OR DELETE ON approval_tasks
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Function to automatically set document version
CREATE OR REPLACE FUNCTION set_document_version()
RETURNS TRIGGER AS $$
BEGIN
    -- If this is a new version of existing document
    IF NEW.parent_version_id IS NOT NULL THEN
        -- Set current version to false for all previous versions
        UPDATE documents
        SET is_current_version = FALSE
        WHERE id = NEW.parent_version_id OR parent_version_id = NEW.parent_version_id;

        -- Set version number
        SELECT COALESCE(MAX(version_number), 0) + 1
        INTO NEW.version_number
        FROM documents
        WHERE id = NEW.parent_version_id OR parent_version_id = NEW.parent_version_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER document_version_trigger
    BEFORE INSERT ON documents
    FOR EACH ROW EXECUTE FUNCTION set_document_version();

-- Function to clean up old file chunks
CREATE OR REPLACE FUNCTION cleanup_old_chunks()
RETURNS void AS $$
BEGIN
    DELETE FROM file_chunks
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;
