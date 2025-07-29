-- Create analytics_podcast_level table
CREATE TABLE analytics_podcast_level (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    podcast_id UUID NOT NULL REFERENCES podcasts(id) ON DELETE CASCADE,
    
    -- Analysis period and dates
    analysis_period VARCHAR(20) DEFAULT 'all_time' CHECK (analysis_period IN ('all_time', 'last_30_days', 'last_90_days', 'last_6_months', 'last_year')),
    analysis_date DATE DEFAULT CURRENT_DATE,
    data_start_date DATE,
    data_end_date DATE,
    
    -- Episode analytics
    total_episodes_analyzed INTEGER DEFAULT 0 CHECK (total_episodes_analyzed >= 0),
    episodes_with_ads INTEGER DEFAULT 0 CHECK (episodes_with_ads >= 0),
    ad_percentage FLOAT GENERATED ALWAYS AS (
        CASE 
            WHEN total_episodes_analyzed > 0 
            THEN ROUND((episodes_with_ads::FLOAT / total_episodes_analyzed * 100)::NUMERIC, 2)
            ELSE 0 
        END
    ) STORED,
    
    -- Content duration analytics
    average_episode_duration INTEGER, -- seconds, for this period
    total_content_duration INTEGER, -- total seconds of content
    
    -- Ad analytics
    total_ads_count INTEGER DEFAULT 0 CHECK (total_ads_count >= 0),
    average_ads_per_episode FLOAT DEFAULT 0 CHECK (average_ads_per_episode >= 0),
    total_ad_duration INTEGER DEFAULT 0 CHECK (total_ad_duration >= 0), -- total seconds across all episodes
    average_ad_duration INTEGER DEFAULT 0 CHECK (average_ad_duration >= 0), -- seconds per ad
    
    -- Sponsor analytics
    unique_sponsors_count INTEGER DEFAULT 0 CHECK (unique_sponsors_count >= 0),
    returning_sponsors_count INTEGER DEFAULT 0 CHECK (returning_sponsors_count >= 0),
    repeat_sponsor_rate FLOAT GENERATED ALWAYS AS (
        CASE 
            WHEN unique_sponsors_count > 0 
            THEN ROUND((returning_sponsors_count::FLOAT / unique_sponsors_count * 100)::NUMERIC, 2)
            ELSE 0 
        END
    ) STORED,
    average_sponsor_frequency FLOAT DEFAULT 0 CHECK (average_sponsor_frequency >= 0), -- average times each sponsor appears
    
    -- Engagement analytics
    average_views_per_episode INTEGER DEFAULT 0 CHECK (average_views_per_episode >= 0),
    average_engagement_rate FLOAT DEFAULT 0 CHECK (average_engagement_rate >= 0), -- across all episodes in period
    total_downloads BIGINT DEFAULT 0 CHECK (total_downloads >= 0), -- if available
    average_likes_per_post INTEGER DEFAULT 0 CHECK (average_likes_per_post >= 0),
    average_comments_per_post INTEGER DEFAULT 0 CHECK (average_comments_per_post >= 0),
    
    -- JSON Analytics Maps
    sponsor_frequency_map JSONB DEFAULT '{}', -- {"sponsor_name_1": 5, "sponsor_name_2": 3}
    sponsor_duration_map JSONB DEFAULT '{}', -- {"sponsor_name_1": 450, "sponsor_name_2": 180} -- total seconds
    category_breakdown JSONB DEFAULT '{}', -- {"technology": {"sponsor_count": 12}, "finance": {"sponsor_count": 5}}
    
    -- Scoring and recommendations
    monetization_score FLOAT DEFAULT 0 CHECK (monetization_score >= 0 AND monetization_score <= 100), -- 0-100 how well monetized
    suitable_brand_categories TEXT[], -- ["technology", "finance", "health"]
    recommended_ad_types TEXT[], -- ["brand_awareness", "direct_response"]
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(podcast_id, analysis_period, analysis_date),
    CHECK (episodes_with_ads <= total_episodes_analyzed),
    CHECK (returning_sponsors_count <= unique_sponsors_count),
    CHECK (data_start_date <= data_end_date OR (data_start_date IS NULL AND data_end_date IS NULL))
);

-- Create indexes for better query performance
CREATE INDEX idx_analytics_podcast_level_podcast_id ON analytics_podcast_level(podcast_id);
CREATE INDEX idx_analytics_podcast_level_analysis_period ON analytics_podcast_level(analysis_period);
CREATE INDEX idx_analytics_podcast_level_analysis_date ON analytics_podcast_level(analysis_date DESC);
CREATE INDEX idx_analytics_podcast_level_monetization_score ON analytics_podcast_level(monetization_score DESC);
CREATE INDEX idx_analytics_podcast_level_total_episodes ON analytics_podcast_level(total_episodes_analyzed DESC);
CREATE INDEX idx_analytics_podcast_level_ad_percentage ON analytics_podcast_level(ad_percentage DESC);

-- Composite indexes for common queries
CREATE INDEX idx_analytics_podcast_period_date ON analytics_podcast_level(podcast_id, analysis_period, analysis_date DESC);
CREATE INDEX idx_analytics_score_episodes ON analytics_podcast_level(monetization_score DESC, total_episodes_analyzed DESC);

-- GIN indexes for arrays and JSONB
CREATE INDEX idx_analytics_suitable_categories ON analytics_podcast_level USING GIN(suitable_brand_categories);
CREATE INDEX idx_analytics_recommended_ad_types ON analytics_podcast_level USING GIN(recommended_ad_types);
CREATE INDEX idx_analytics_sponsor_frequency ON analytics_podcast_level USING GIN(sponsor_frequency_map);
CREATE INDEX idx_analytics_sponsor_duration ON analytics_podcast_level USING GIN(sponsor_duration_map);
CREATE INDEX idx_analytics_category_breakdown ON analytics_podcast_level USING GIN(category_breakdown);

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_analytics_podcast_level_updated_at
    BEFORE UPDATE ON analytics_podcast_level
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Example inserts to test the table structure
-- INSERT INTO analytics_podcast_level (
--     podcast_id,
--     analysis_period,
--     analysis_date,
--     data_start_date,
--     data_end_date,
--     total_episodes_analyzed,
--     episodes_with_ads,
--     average_episode_duration,
--     total_content_duration,
--     total_ads_count,
--     average_ads_per_episode,
--     total_ad_duration,
--     average_ad_duration,
--     unique_sponsors_count,
--     returning_sponsors_count,
--     average_sponsor_frequency,
--     average_views_per_episode,
--     average_engagement_rate,
--     total_downloads,
--     average_likes_per_post,
--     average_comments_per_post,
--     sponsor_frequency_map,
--     sponsor_duration_map,
--     category_breakdown,
--     monetization_score,
--     suitable_brand_categories,
--     recommended_ad_types
-- ) VALUES (
--     -- Replace with actual podcast_id from podcasts table
--     (SELECT id FROM podcasts LIMIT 1),
--     'all_time',
--     CURRENT_DATE,
--     '2023-01-01',
--     CURRENT_DATE,
--     156, -- total episodes analyzed
--     124, -- episodes with ads
--     1800, -- 30 minutes average duration
--     280800, -- total content duration in seconds
--     248, -- total ads count
--     2.0, -- average ads per episode
--     14880, -- total ad duration (248 ads * 60 seconds avg)
--     60, -- average ad duration
--     25, -- unique sponsors
--     18, -- returning sponsors
--     2.8, -- average sponsor frequency
--     12500, -- average views per episode
--     7.5, -- average engagement rate
--     1950000, -- total downloads
--     95, -- average likes per episode
--     23, -- average comments per episode
--     '{
--         "TechCorp Solutions": 12,
--         "HealthyLife Supplements": 8,
--         "CryptoTrading Pro": 15,
--         "LearnCode Academy": 6,
--         "ProductivityApp": 9
--     }'::jsonb,
--     '{
--         "TechCorp Solutions": 720,
--         "HealthyLife Supplements": 360,
--         "CryptoTrading Pro": 900,
--         "LearnCode Academy": 300,
--         "ProductivityApp": 450
--     }'::jsonb,
--     '{
--         "technology": {"sponsor_count": 15, "total_duration": 1200, "avg_duration": 80},
--         "health": {"sponsor_count": 8, "total_duration": 360, "avg_duration": 45},
--         "finance": {"sponsor_count": 15, "total_duration": 900, "avg_duration": 60},
--         "education": {"sponsor_count": 6, "total_duration": 300, "avg_duration": 50},
--         "productivity": {"sponsor_count": 9, "total_duration": 450, "avg_duration": 50}
--     }'::jsonb,
--     85.5, -- monetization score
--     ARRAY['technology', 'business software', 'productivity', 'finance'],
--     ARRAY['direct_response', 'brand_awareness', 'sponsored_content']
-- );

-- INSERT INTO analytics_podcast_level (
--     podcast_id,
--     analysis_period,
--     analysis_date,
--     data_start_date,
--     data_end_date,
--     total_episodes_analyzed,
--     episodes_with_ads,
--     average_episode_duration,
--     total_content_duration,
--     total_ads_count,
--     average_ads_per_episode,
--     total_ad_duration,
--     average_ad_duration,
--     unique_sponsors_count,
--     returning_sponsors_count,
--     average_sponsor_frequency,
--     average_views_per_episode,
--     monetization_score,
--     suitable_brand_categories,
--     recommended_ad_types
-- ) VALUES (
--     -- Replace with actual podcast_id from podcasts table
--     (SELECT id FROM podcasts LIMIT 1),
--     'last_30_days',
--     CURRENT_DATE,
--     CURRENT_DATE - INTERVAL '30 days',
--     CURRENT_DATE,
--     8, -- episodes in last 30 days
--     6, -- episodes with ads
--     1950, -- slightly longer recent episodes
--     15600, -- total content duration
--     12, -- total ads count
--     2.0, -- average ads per episode
--     720, -- total ad duration
--     60, -- average ad duration
--     4, -- unique sponsors in period
--     2, -- returning sponsors
--     1.5, -- average sponsor frequency
--     13200, -- recent viewership higher
--     78.0, -- monetization score for recent period
--     ARRAY['technology', 'business software'],
--     ARRAY['direct_response', 'sponsored_content']
-- );

-- Useful analytics queries for testing
-- -- Get latest analytics for all podcasts
-- SELECT 
--     p.name as podcast_name,
--     apl.analysis_period,
--     apl.total_episodes_analyzed,
--     apl.ad_percentage,
--     apl.monetization_score,
--     apl.unique_sponsors_count,
--     apl.average_views_per_episode
-- FROM analytics_podcast_level apl
-- JOIN podcasts p ON apl.podcast_id = p.id
-- WHERE apl.analysis_date = CURRENT_DATE
-- ORDER BY apl.monetization_score DESC;

-- -- Get sponsor frequency details
-- SELECT 
--     p.name as podcast_name,
--     apl.sponsor_frequency_map,
--     apl.category_breakdown
-- FROM analytics_podcast_level apl
-- JOIN podcasts p ON apl.podcast_id = p.id
-- WHERE apl.analysis_period = 'all_time'
-- ORDER BY apl.monetization_score DESC;