-- Create ad type enum
CREATE TYPE ad_type_enum AS ENUM (
    'direct_response',
    'brand_awareness',
    'sponsored_content',
    'affiliate'
);

-- Create sponsors table (referenced by episode_sponsors)
-- Note: This assumes sponsors table doesn't exist yet
CREATE TABLE IF NOT EXISTS sponsors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(500) NOT NULL,
    domain VARCHAR(255),
    website_url TEXT,
    category VARCHAR(255),
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create episode_sponsors table
CREATE TABLE episode_sponsors (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    episode_id UUID NOT NULL REFERENCES episodes(id) ON DELETE CASCADE,
    sponsor_id UUID NOT NULL REFERENCES sponsors(id) ON DELETE CASCADE,
    
    -- Ad timing
    start_time INTEGER NOT NULL, -- seconds from episode start
    end_time INTEGER NOT NULL, -- seconds from episode start
    
    -- Ad classification
    ad_type ad_type_enum DEFAULT 'brand_awareness',
    
    -- Ad content details
    call_to_action TEXT,
    promo_code VARCHAR(100),
    website_mentioned VARCHAR(255),
    product_mentioned VARCHAR(500),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CHECK (end_time > start_time),
    CHECK (start_time >= 0),
    CHECK (end_time >= 0)
);

-- Create indexes for better query performance
CREATE INDEX idx_episode_sponsors_episode_id ON episode_sponsors(episode_id);
CREATE INDEX idx_episode_sponsors_sponsor_id ON episode_sponsors(sponsor_id);
CREATE INDEX idx_episode_sponsors_ad_type ON episode_sponsors(ad_type);
CREATE INDEX idx_episode_sponsors_start_time ON episode_sponsors(start_time);
CREATE INDEX idx_episode_sponsors_promo_code ON episode_sponsors(promo_code);

-- Composite indexes for common queries
CREATE INDEX idx_episode_sponsors_episode_time ON episode_sponsors(episode_id, start_time);
CREATE INDEX idx_episode_sponsors_sponsor_type ON episode_sponsors(sponsor_id, ad_type);

-- Index on sponsors table
CREATE INDEX idx_sponsors_name ON sponsors(name);
CREATE INDEX idx_sponsors_domain ON sponsors(domain);
CREATE INDEX idx_sponsors_category ON sponsors(category);
CREATE INDEX idx_sponsors_is_verified ON sponsors(is_verified);

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_episode_sponsors_updated_at
    BEFORE UPDATE ON episode_sponsors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sponsors_updated_at
    BEFORE UPDATE ON sponsors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add computed column for ad duration
ALTER TABLE episode_sponsors 
ADD COLUMN duration INTEGER GENERATED ALWAYS AS (end_time - start_time) STORED;

-- Create index on computed duration column
CREATE INDEX idx_episode_sponsors_duration ON episode_sponsors(duration);

-- Example inserts to test the table structure
-- First insert some example sponsors
-- INSERT INTO sponsors (name, domain, website_url, category, is_verified) VALUES
-- ('TechCorp Solutions', 'techcorp.com', 'https://techcorp.com', 'Software', true),
-- ('HealthyLife Supplements', 'healthylife.com', 'https://healthylife.com', 'Health & Wellness', true),
-- ('CryptoTrading Pro', 'cryptopro.com', 'https://cryptopro.com', 'Finance', false),
-- ('LearnCode Academy', 'learncode.edu', 'https://learncode.edu', 'Education', true);

-- Then insert episode sponsor records
-- INSERT INTO episode_sponsors (
--     episode_id,
--     sponsor_id,
--     start_time,
--     end_time,
--     ad_type,
--     call_to_action,
--     promo_code,
--     website_mentioned,
--     product_mentioned
-- ) VALUES (
--     -- Replace with actual episode_id from episodes table
--     (SELECT id FROM episodes LIMIT 1),
--     (SELECT id FROM sponsors WHERE name = 'TechCorp Solutions'),
--     120, -- 2 minutes into episode
--     180, -- 3 minutes into episode (60 second ad)
--     'direct_response',
--     'Visit techcorp.com/podcast and start your free trial today',
--     'PODCAST30',
--     'techcorp.com/podcast',
--     'CRM Software Suite'
-- );

-- INSERT INTO episode_sponsors (
--     episode_id,
--     sponsor_id,
--     start_time,
--     end_time,
--     ad_type,
--     call_to_action,
--     promo_code,
--     website_mentioned,
--     product_mentioned
-- ) VALUES (
--     -- Replace with actual episode_id from episodes table
--     (SELECT id FROM episodes LIMIT 1),
--     (SELECT id FROM sponsors WHERE name = 'HealthyLife Supplements'),
--     900, -- 15 minutes into episode
--     945, -- 15:45 into episode (45 second ad)
--     'affiliate',
--     'Use my link below to get 20% off your first order',
--     'HEALTHY20',
--     'healthylife.com/partners/podcast',
--     'Daily Vitamin Pack'
-- );

-- INSERT INTO episode_sponsors (
--     episode_id,
--     sponsor_id,
--     start_time,
--     end_time,
--     ad_type,
--     call_to_action,
--     website_mentioned,
--     product_mentioned
-- ) VALUES (
--     -- Replace with actual episode_id from episodes table
--     (SELECT id FROM episodes LIMIT 1),
--     (SELECT id FROM sponsors WHERE name = 'LearnCode Academy'),
--     1680, -- 28 minutes into episode
--     1740, -- 29 minutes into episode (60 second ad)
--     'sponsored_content',
--     'Check out their advanced JavaScript course',
--     'learncode.edu/javascript',
--     'JavaScript Mastery Course'
-- );

-- Useful queries for testing
-- SELECT 
--     e.title as episode_title,
--     s.name as sponsor_name,
--     es.ad_type,
--     es.start_time,
--     es.end_time,
--     es.duration,
--     es.promo_code,
--     es.product_mentioned
-- FROM episode_sponsors es
-- JOIN episodes e ON es.episode_id = e.id
-- JOIN sponsors s ON es.sponsor_id = s.id
-- ORDER BY e.published_at DESC, es.start_time;