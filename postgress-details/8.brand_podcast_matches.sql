-- Create match status enum
CREATE TYPE match_status_enum AS ENUM (
    'suggested',
    'reviewed',
    'contacted',
    'negotiating',
    'accepted',
    'rejected',
    'booked',
    'completed'
);

-- Create brand_podcast_matches table
CREATE TABLE brand_podcast_matches (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES brand_profiles(id) ON DELETE CASCADE,
    podcast_id UUID NOT NULL REFERENCES podcasts(id) ON DELETE CASCADE,
    campaign_id UUID NOT NULL REFERENCES brand_campaigns(id) ON DELETE CASCADE,
    
    -- Overall matching scores
    overall_score FLOAT NOT NULL CHECK (overall_score >= 0 AND overall_score <= 100),
    match_confidence FLOAT CHECK (match_confidence >= 0 AND match_confidence <= 100),
    
    -- Granular matching scores (based on campaign embeddings)
    audience_match_score FLOAT CHECK (audience_match_score >= 0 AND audience_match_score <= 100), -- campaign_audience_embedding ↔ podcast.audience_embedding
    product_relevance_score FLOAT CHECK (product_relevance_score >= 0 AND product_relevance_score <= 100), -- campaign_product_embedding ↔ podcast.content_embedding
    content_theme_score FLOAT CHECK (content_theme_score >= 0 AND content_theme_score <= 100), -- campaign_content_embedding ↔ podcast.content_embedding
    brand_alignment_score FLOAT CHECK (brand_alignment_score >= 0 AND brand_alignment_score <= 100), -- campaign_brand_embedding ↔ podcast.content_embedding
    
    -- Demographic compatibility scores
    geographic_overlap_score FLOAT CHECK (geographic_overlap_score >= 0 AND geographic_overlap_score <= 100), -- country/region alignment percentage
    age_compatibility_score FLOAT CHECK (age_compatibility_score >= 0 AND age_compatibility_score <= 100), -- age range overlap score
    gender_alignment_score FLOAT CHECK (gender_alignment_score >= 0 AND gender_alignment_score <= 100), -- gender targeting alignment
    interest_overlap_score FLOAT CHECK (interest_overlap_score >= 0 AND interest_overlap_score <= 100), -- interests intersection percentage
    
    -- Performance & quality scores
    engagement_quality_score FLOAT CHECK (engagement_quality_score >= 0 AND engagement_quality_score <= 100), -- podcast engagement metrics score
    audience_size_score FLOAT CHECK (audience_size_score >= 0 AND audience_size_score <= 100), -- how well podcast size fits campaign needs
    monetization_readiness_score FLOAT CHECK (monetization_readiness_score >= 0 AND monetization_readiness_score <= 100), -- how sponsor-friendly the podcast is
    growth_potential_score FLOAT CHECK (growth_potential_score >= 0 AND growth_potential_score <= 100), -- podcast growth trajectory score
    
    -- Budget & economics
    estimated_cpm DECIMAL(8,2) CHECK (estimated_cpm >= 0), -- estimated cost per thousand impressions
    estimated_cost_per_episode DECIMAL(10,2) CHECK (estimated_cost_per_episode >= 0), -- estimated cost for one episode
    budget_fit_score FLOAT CHECK (budget_fit_score >= 0 AND budget_fit_score <= 100), -- how well podcast fits campaign budget
    potential_reach INTEGER CHECK (potential_reach >= 0), -- estimated campaign reach
    potential_impressions BIGINT CHECK (potential_impressions >= 0), -- estimated total impressions
    
    -- Match reasoning & context
    match_reasoning JSONB DEFAULT '{}', -- Detailed breakdown of why this match was made
    algorithm_version VARCHAR(20), -- which algorithm version generated this match
    embedding_model_version VARCHAR(50), -- which embedding model was used
    
    -- Status & workflow
    status match_status_enum DEFAULT 'suggested',
    priority VARCHAR(20) CHECK (priority IN ('high', 'medium', 'low')),
    internal_notes TEXT, -- team notes about this match
    brand_feedback TEXT, -- brand's feedback on this suggestion
    
    -- Communication tracking
    contact_attempted_at TIMESTAMP, -- when outreach was attempted
    response_received_at TIMESTAMP, -- when podcast responded
    meeting_scheduled_at TIMESTAMP, -- if meeting was scheduled
    deal_closed_at TIMESTAMP, -- if deal was finalized
    
    -- Performance tracking (actual results)
    actual_cpm DECIMAL(8,2), -- actual cost per thousand impressions
    actual_cost DECIMAL(10,2), -- actual cost paid
    actual_reach INTEGER, -- actual campaign reach achieved
    actual_impressions BIGINT, -- actual impressions delivered
    actual_ctr FLOAT, -- actual click-through rate
    actual_conversions INTEGER, -- actual conversions generated
    roi FLOAT, -- return on investment
    
    -- Timestamps
    match_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- when match was generated
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(brand_id, podcast_id, campaign_id),
    CHECK (contact_attempted_at >= match_date OR contact_attempted_at IS NULL),
    CHECK (response_received_at >= contact_attempted_at OR response_received_at IS NULL),
    CHECK (deal_closed_at >= contact_attempted_at OR deal_closed_at IS NULL)
);

-- Create indexes for better query performance
CREATE INDEX idx_brand_podcast_matches_brand_id ON brand_podcast_matches(brand_id);
CREATE INDEX idx_brand_podcast_matches_podcast_id ON brand_podcast_matches(podcast_id);
CREATE INDEX idx_brand_podcast_matches_campaign_id ON brand_podcast_matches(campaign_id);
CREATE INDEX idx_brand_podcast_matches_overall_score ON brand_podcast_matches(overall_score DESC);
CREATE INDEX idx_brand_podcast_matches_status ON brand_podcast_matches(status);
CREATE INDEX idx_brand_podcast_matches_priority ON brand_podcast_matches(priority);
CREATE INDEX idx_brand_podcast_matches_match_date ON brand_podcast_matches(match_date DESC);

-- Indexes on specific score types
CREATE INDEX idx_brand_podcast_matches_audience_score ON brand_podcast_matches(audience_match_score DESC);
CREATE INDEX idx_brand_podcast_matches_product_score ON brand_podcast_matches(product_relevance_score DESC);
CREATE INDEX idx_brand_podcast_matches_content_score ON brand_podcast_matches(content_theme_score DESC);
CREATE INDEX idx_brand_podcast_matches_brand_score ON brand_podcast_matches(brand_alignment_score DESC);

-- Economic and performance indexes
CREATE INDEX idx_brand_podcast_matches_estimated_cpm ON brand_podcast_matches(estimated_cpm);
CREATE INDEX idx_brand_podcast_matches_budget_fit ON brand_podcast_matches(budget_fit_score DESC);
CREATE INDEX idx_brand_podcast_matches_potential_reach ON brand_podcast_matches(potential_reach DESC);
CREATE INDEX idx_brand_podcast_matches_roi ON brand_podcast_matches(roi DESC);

-- Composite indexes for common queries
CREATE INDEX idx_brand_podcast_matches_campaign_score ON brand_podcast_matches(campaign_id, overall_score DESC);
CREATE INDEX idx_brand_podcast_matches_brand_score ON brand_podcast_matches(brand_id, overall_score DESC);
CREATE INDEX idx_brand_podcast_matches_status_score ON brand_podcast_matches(status, overall_score DESC);
CREATE INDEX idx_brand_podcast_matches_priority_score ON brand_podcast_matches(priority, overall_score DESC);

-- GIN index for JSONB match reasoning
CREATE INDEX idx_brand_podcast_matches_reasoning ON brand_podcast_matches USING GIN(match_reasoning);

-- Partial indexes for active matches
CREATE INDEX idx_brand_podcast_matches_active_high_score ON brand_podcast_matches(overall_score DESC) 
WHERE status IN ('suggested', 'reviewed', 'contacted', 'negotiating');

CREATE INDEX idx_brand_podcast_matches_completed ON brand_podcast_matches(actual_roi DESC, actual_reach DESC) 
WHERE status = 'completed';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_brand_podcast_matches_updated_at
    BEFORE UPDATE ON brand_podcast_matches
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Example inserts to test the table structure
-- INSERT INTO brand_podcast_matches (
--     brand_id,
--     podcast_id,
--     campaign_id,
--     overall_score,
--     match_confidence,
--     audience_match_score,
--     product_relevance_score,
--     content_theme_score,
--     brand_alignment_score,
--     geographic_overlap_score,
--     age_compatibility_score,
--     gender_alignment_score,
--     interest_overlap_score,
--     engagement_quality_score,
--     audience_size_score,
--     monetization_readiness_score,
--     growth_potential_score,
--     estimated_cpm,
--     estimated_cost_per_episode,
--     budget_fit_score,
--     potential_reach,
--     potential_impressions,
--     match_reasoning,
--     algorithm_version,
--     status,
--     priority
-- ) VALUES (
--     -- Replace with actual IDs from respective tables
--     (SELECT id FROM brand_profiles WHERE name = 'TechCorp Solutions'),
--     (SELECT id FROM podcasts LIMIT 1),
--     (SELECT id FROM brand_campaigns WHERE name = 'Q4 CRM Software Launch'),
--     87.5, -- overall score
--     92.0, -- match confidence
--     89.0, -- audience match score
--     85.0, -- product relevance score
--     88.0, -- content theme score
--     83.0, -- brand alignment score
--     95.0, -- geographic overlap score (US focus matches)
--     92.0, -- age compatibility score (25-55 overlaps well)
--     100.0, -- gender alignment score (targeting 'all')
--     87.0, -- interest overlap score (business, productivity)
--     78.0, -- engagement quality score
--     85.0, -- audience size score (45K audience fits budget)
--     82.0, -- monetization readiness score
--     75.0, -- growth potential score
--     24.50, -- estimated CPM
--     2100.00, -- estimated cost per episode
--     95.0, -- budget fit score (within $2500 budget)
--     45000, -- potential reach
--     2250000, -- potential impressions
--     '{
--         "top_strengths": [
--             "Perfect audience age overlap (92%)",
--             "High content relevance to CRM and business tools",
--             "Geographic targeting matches exactly (US focus)",
--             "Podcast actively discusses productivity software"
--         ],
--         "potential_concerns": [
--             "CPM slightly below optimal range",
--             "Limited previous SaaS sponsor history"
--         ],
--         "key_metrics": {
--             "audience_size": 45000,
--             "monthly_downloads": 180000,
--             "engagement_rate": 7.8,
--             "avg_episode_duration": 1800,
--             "sponsor_frequency": "moderate"
--         },
--         "recommendation": "Excellent fit for B2B SaaS campaign targeting sales professionals",
--         "optimal_ad_placement": "mid-roll",
--         "suggested_approach": "Host-read testimonial style ad focusing on productivity benefits"
--     }'::jsonb,
--     'v2.1.0',
--     'suggested',
--     'high'
-- );

-- INSERT INTO brand_podcast_matches (
--     brand_id,
--     podcast_id,
--     campaign_id,
--     overall_score,
--     match_confidence,
--     audience_match_score,
--     product_relevance_score,
--     content_theme_score,
--     brand_alignment_score,
--     geographic_overlap_score,
--     age_compatibility_score,
--     gender_alignment_score,
--     interest_overlap_score,
--     engagement_quality_score,
--     audience_size_score,
--     monetization_readiness_score,
--     growth_potential_score,
--     estimated_cpm,
--     estimated_cost_per_episode,
--     budget_fit_score,
--     potential_reach,
--     potential_impressions,
--     match_reasoning,
--     status,
--     priority
-- ) VALUES (
--     -- Replace with actual IDs from respective tables
--     (SELECT id FROM brand_profiles WHERE name = 'FitLife Supplements'),
--     (SELECT id FROM podcasts LIMIT 1),
--     (SELECT id FROM brand_campaigns WHERE name = 'Winter Wellness Campaign'),
--     78.5, -- overall score
--     85.0, -- match confidence
--     82.0, -- audience match score
--     75.0, -- product relevance score
--     79.0, -- content theme score
--     76.0, -- brand alignment score
--     90.0, -- geographic overlap score
--     88.0, -- age compatibility score
--     100.0, -- gender alignment score
--     85.0, -- interest overlap score
--     72.0, -- engagement quality score
--     78.0, -- audience size score
--     65.0, -- monetization readiness score
--     85.0, -- growth potential score (growing health podcast)
--     16.00, -- estimated CPM
--     680.00, -- estimated cost per episode
--     92.0, -- budget fit score (well within $800 budget)
--     25000, -- potential reach
--     1562500, -- potential impressions
--     '{
--         "top_strengths": [
--             "Strong alignment with health and wellness focus",
--             "Audience demographics match target age group",
--             "Growing engagement in health/fitness space",
--             "Budget-friendly option with good reach"
--         ],
--         "potential_concerns": [
--             "Lower previous supplement sponsor experience",
--             "Engagement rate below premium threshold"
--         ],
--         "key_metrics": {
--             "audience_size": 25000,
--             "monthly_downloads": 95000,
--             "engagement_rate": 6.2,
--             "health_content_percentage": 85
--         },
--         "recommendation": "Good fit for wellness brand, consider as secondary option",
--         "optimal_ad_placement": "post-roll",
--         "suggested_approach": "Natural integration discussing winter health tips"
--     }'::jsonb,
--     'suggested',
--     'medium'
-- );

-- Useful queries for testing
-- -- Get top matches for a specific campaign
-- SELECT 
--     bp.name as brand_name,
--     p.name as podcast_name,
--     bc.name as campaign_name,
--     bpm.overall_score,
--     bpm.audience_match_score,
--     bpm.estimated_cost_per_episode,
--     bpm.potential_reach,
--     bpm.status,
--     bpm.priority
-- FROM brand_podcast_matches bpm
-- JOIN brand_profiles bp ON bpm.brand_id = bp.id
-- JOIN podcasts p ON bpm.podcast_id = p.id
-- JOIN brand_campaigns bc ON bpm.campaign_id = bc.id
-- WHERE bc.name = 'Q4 CRM Software Launch'
-- ORDER BY bpm.overall_score DESC
-- LIMIT 10;

-- -- Get match performance summary
-- SELECT 
--     status,
--     COUNT(*) as match_count,
--     AVG(overall_score) as avg_score,
--     AVG(estimated_cost_per_episode) as avg_cost,
--     SUM(potential_reach) as total_potential_reach
-- FROM brand_podcast_matches
-- GROUP BY status
-- ORDER BY match_count DESC;