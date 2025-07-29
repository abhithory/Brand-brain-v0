-- Create campaign type enum
CREATE TYPE campaign_type_enum AS ENUM (
    'brand_awareness',
    'direct_response', 
    'lead_generation',
    'product_launch',
    'event_promotion'
);

-- Create gender enum
CREATE TYPE gender_enum AS ENUM (
    'male',
    'female',
    'non_binary',
    'all'
);

-- Create campaign status enum  
CREATE TYPE campaign_status_enum AS ENUM (
    'draft',
    'active',
    'paused',
    'completed',
    'cancelled'
);

-- Create brand_campaigns table
CREATE TABLE brand_campaigns (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES brand_profiles(id) ON DELETE CASCADE,
    name VARCHAR(500) NOT NULL,
    description TEXT, -- campaign details and objectives
    
    -- Campaign specifics
    product_focus VARCHAR(500), -- specific product/service being promoted
    campaign_type campaign_type_enum NOT NULL,
    campaign_objective VARCHAR(255), -- "increase signups", "drive sales", "build awareness"
    
    -- Target audience (campaign-specific)
    target_gender gender_enum DEFAULT 'all',
    target_age_min INTEGER CHECK (target_age_min >= 13 AND target_age_min <= 100),
    target_age_max INTEGER CHECK (target_age_max >= 13 AND target_age_max <= 100),
    target_countries VARCHAR(10)[], -- ["US", "CA", "UK"]
    target_interests TEXT[], -- campaign-specific interests
    target_demographics JSONB DEFAULT '{}', -- detailed targeting
    
    -- Budget & performance targets
    total_budget DECIMAL(12,2) CHECK (total_budget >= 0),
    budget_per_episode DECIMAL(10,2) CHECK (budget_per_episode >= 0),
    min_budget_per_episode DECIMAL(10,2) CHECK (min_budget_per_episode >= 0),
    target_cpm DECIMAL(8,2) CHECK (target_cpm >= 0), -- target cost per thousand impressions
    
    -- Performance goals
    target_aov DECIMAL(10,2) CHECK (target_aov >= 0), -- target Average Order Value
    target_ctr FLOAT CHECK (target_ctr >= 0 AND target_ctr <= 100), -- target Click Through Rate percentage
    target_conversion_rate FLOAT CHECK (target_conversion_rate >= 0 AND target_conversion_rate <= 100), -- target conversion percentage
    target_reach INTEGER CHECK (target_reach >= 0), -- desired audience reach
    target_impressions BIGINT CHECK (target_impressions >= 0), -- desired total impressions
    
    -- Content requirements
    ad_duration_preference VARCHAR(50) CHECK (ad_duration_preference IN ('30-second', '60-second', '90-second', 'flexible')),
    ad_position_preference TEXT[], -- ["pre-roll", "mid-roll", "post-roll"]
    call_to_action VARCHAR(500), -- preferred CTA
    promo_code VARCHAR(100), -- campaign-specific discount code
    
    -- Matching preferences
    podcast_categories TEXT[], -- preferred podcast categories
    audience_size_min INTEGER CHECK (audience_size_min >= 0), -- minimum podcast audience size
    audience_size_max INTEGER CHECK (audience_size_max >= 0), -- maximum podcast audience size
    engagement_rate_min FLOAT CHECK (engagement_rate_min >= 0 AND engagement_rate_min <= 100), -- minimum podcast engagement rate
    exclude_explicit_content BOOLEAN DEFAULT false,
    
    -- Campaign status & dates
    status campaign_status_enum DEFAULT 'draft',
    start_date DATE,
    end_date DATE,
    
    -- Performance tracking
    actual_spend DECIMAL(12,2) DEFAULT 0 CHECK (actual_spend >= 0),
    actual_reach INTEGER DEFAULT 0 CHECK (actual_reach >= 0),
    actual_impressions BIGINT DEFAULT 0 CHECK (actual_impressions >= 0),
    actual_ctr FLOAT DEFAULT 0 CHECK (actual_ctr >= 0 AND actual_ctr <= 100),
    actual_conversions INTEGER DEFAULT 0 CHECK (actual_conversions >= 0),
    
    -- Campaign embeddings for matching
    campaign_brand_embedding vector(1536), -- brand values + campaign messaging + brand voice
    campaign_audience_embedding vector(1536), -- campaign target demographics + interests + audience profile  
    campaign_product_embedding vector(1536), -- specific product focus + features + use cases
    campaign_content_embedding vector(1536), -- campaign themes + preferred topics + content guidelines
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CHECK (target_age_max >= target_age_min OR (target_age_min IS NULL AND target_age_max IS NULL)),
    CHECK (start_date <= end_date OR (start_date IS NULL AND end_date IS NULL)),
    CHECK (budget_per_episode >= min_budget_per_episode OR (budget_per_episode IS NULL AND min_budget_per_episode IS NULL)),
    CHECK (audience_size_max >= audience_size_min OR (audience_size_min IS NULL AND audience_size_max IS NULL))
);

-- Create indexes for better query performance
CREATE INDEX idx_brand_campaigns_brand_id ON brand_campaigns(brand_id);
CREATE INDEX idx_brand_campaigns_campaign_type ON brand_campaigns(campaign_type);
CREATE INDEX idx_brand_campaigns_status ON brand_campaigns(status);
CREATE INDEX idx_brand_campaigns_target_gender ON brand_campaigns(target_gender);
CREATE INDEX idx_brand_campaigns_total_budget ON brand_campaigns(total_budget DESC);
CREATE INDEX idx_brand_campaigns_target_cpm ON brand_campaigns(target_cpm);
CREATE INDEX idx_brand_campaigns_start_date ON brand_campaigns(start_date);
CREATE INDEX idx_brand_campaigns_end_date ON brand_campaigns(end_date);
CREATE INDEX idx_brand_campaigns_actual_spend ON brand_campaigns(actual_spend DESC);

-- GIN indexes for arrays and JSONB
CREATE INDEX idx_brand_campaigns_target_countries ON brand_campaigns USING GIN(target_countries);
CREATE INDEX idx_brand_campaigns_target_interests ON brand_campaigns USING GIN(target_interests);
CREATE INDEX idx_brand_campaigns_target_demographics ON brand_campaigns USING GIN(target_demographics);
CREATE INDEX idx_brand_campaigns_ad_position_preference ON brand_campaigns USING GIN(ad_position_preference);
CREATE INDEX idx_brand_campaigns_podcast_categories ON brand_campaigns USING GIN(podcast_categories);

-- Vector similarity indexes for all campaign embeddings
CREATE INDEX idx_brand_campaigns_brand_embedding ON brand_campaigns USING ivfflat (campaign_brand_embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_brand_campaigns_audience_embedding ON brand_campaigns USING ivfflat (campaign_audience_embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_brand_campaigns_product_embedding ON brand_campaigns USING ivfflat (campaign_product_embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_brand_campaigns_content_embedding ON brand_campaigns USING ivfflat (campaign_content_embedding vector_cosine_ops) WITH (lists = 100);

-- Composite indexes for common queries
CREATE INDEX idx_brand_campaigns_brand_status ON brand_campaigns(brand_id, status);
CREATE INDEX idx_brand_campaigns_type_status ON brand_campaigns(campaign_type, status);
CREATE INDEX idx_brand_campaigns_budget_range ON brand_campaigns(budget_per_episode, target_cpm);
CREATE INDEX idx_brand_campaigns_dates_active ON brand_campaigns(start_date, end_date) WHERE status = 'active';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_brand_campaigns_updated_at
    BEFORE UPDATE ON brand_campaigns
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Example inserts to test the table structure
-- INSERT INTO brand_campaigns (
--     brand_id,
--     name,
--     description,
--     product_focus,
--     campaign_type,
--     campaign_objective,
--     target_gender,
--     target_age_min,
--     target_age_max,
--     target_countries,
--     target_interests,
--     target_demographics,
--     total_budget,
--     budget_per_episode,
--     min_budget_per_episode,
--     target_cpm,
--     target_aov,
--     target_ctr,
--     target_conversion_rate,
--     target_reach,
--     target_impressions,
--     ad_duration_preference,
--     ad_position_preference,
--     call_to_action,
--     promo_code,
--     podcast_categories,
--     audience_size_min,
--     audience_size_max,
--     engagement_rate_min,
--     exclude_explicit_content,
--     status,
--     start_date,
--     end_date
-- ) VALUES (
--     -- Replace with actual brand_id from brand_profiles table
--     (SELECT id FROM brand_profiles WHERE name = 'TechCorp Solutions'),
--     'Q4 CRM Software Launch',
--     'Major campaign to launch our new CRM Pro Suite targeting small to medium businesses. Focus on converting trial users to paid customers.',
--     'CRM Pro Suite',
--     'product_launch',
--     'drive sales and increase trial signups',
--     'all',
--     25,
--     55,
--     ARRAY['US', 'CA', 'UK'],
--     ARRAY['business software', 'CRM', 'sales tools', 'productivity', 'small business'],
--     '{
--         "job_titles": ["Sales Manager", "Business Owner", "Operations Manager"],
--         "company_sizes": ["1-50 employees", "51-200 employees"],
--         "pain_points": ["manual sales tracking", "lead management", "customer communication"],
--         "buying_behavior": ["researches extensively", "values ROI", "seeks recommendations"]
--     }'::jsonb,
--     50000.00, -- total budget
--     2500.00, -- budget per episode
--     1000.00, -- min budget per episode
--     25.00, -- target CPM
--     199.00, -- target AOV (monthly subscription)
--     3.5, -- target CTR
--     12.0, -- target conversion rate
--     200000, -- target reach
--     5000000, -- target impressions
--     '60-second',
--     ARRAY['mid-roll', 'pre-roll'],
--     'Start your free 30-day trial of CRM Pro Suite at techcorp.com/crm-trial',
--     'PODCAST30',
--     ARRAY['business', 'entrepreneurship', 'sales', 'productivity'],
--     10000, -- min audience size
--     100000, -- max audience size
--     5.0, -- min engagement rate
--     true, -- exclude explicit content
--     'active',
--     '2024-10-01',
--     '2024-12-31'
-- );

-- INSERT INTO brand_campaigns (
--     brand_id,
--     name,
--     description,
--     product_focus,
--     campaign_type,
--     campaign_objective,
--     target_gender,
--     target_age_min,
--     target_age_max,
--     target_countries,
--     target_interests,
--     total_budget,
--     budget_per_episode,
--     min_budget_per_episode,
--     target_cpm,
--     target_aov,
--     target_ctr,
--     ad_duration_preference,
--     ad_position_preference,
--     call_to_action,
--     promo_code,
--     podcast_categories,
--     audience_size_min,
--     engagement_rate_min,
--     status,
--     start_date,
--     end_date
-- ) VALUES (
--     -- Replace with actual brand_id from brand_profiles table  
--     (SELECT id FROM brand_profiles WHERE name = 'FitLife Supplements'),
--     'Winter Wellness Campaign',
--     'Promote our Daily Essentials Pack during cold season when people focus on immune health and wellness.',
--     'Daily Essentials Pack',
--     'brand_awareness',
--     'increase brand awareness and drive supplement sales',
--     'all',
--     22,
--     45,
--     ARRAY['US', 'CA'],
--     ARRAY['health', 'wellness', 'fitness', 'nutrition', 'immune support'],
--     15000.00, -- total budget
--     800.00, -- budget per episode
--     300.00, -- min budget per episode
--     18.00, -- target CPM
--     45.00, -- target AOV
--     4.2, -- target CTR
--     'flexible',
--     ARRAY['mid-roll', 'post-roll'],
--     'Get 25% off your first order at fitlifesupplements.com with code WINTER25',
--     'WINTER25',
--     ARRAY['health', 'fitness', 'wellness', 'lifestyle'],
--     5000, -- min audience size
--     3.0, -- min engagement rate
--     'active',
--     '2024-11-01',
--     '2025-02-28'
-- );

-- Useful queries for testing
-- SELECT 
--     c.name as campaign_name,
--     b.name as brand_name,
--     c.campaign_type,
--     c.status,
--     c.total_budget,
--     c.target_countries,
--     c.target_interests,
--     c.podcast_categories
-- FROM brand_campaigns c
-- JOIN brand_profiles b ON c.brand_id = b.id
-- WHERE c.status = 'active'
-- ORDER BY c.total_budget DESC;

-- -- Find campaigns targeting specific demographics
-- SELECT 
--     c.name,
--     c.target_age_min,
--     c.target_age_max,
--     c.target_gender,
--     c.target_countries,
--     c.budget_per_episode
-- FROM brand_campaigns c
-- WHERE c.target_age_min <= 35 AND c.target_age_max >= 25
-- AND 'US' = ANY(c.target_countries)
-- AND c.status IN ('active', 'draft')
-- ORDER BY c.budget_per_episode DESC;