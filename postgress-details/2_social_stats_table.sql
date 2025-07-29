-- Create platform enum type
CREATE TYPE platform_enum AS ENUM (
    'instagram',
    'youtube', 
    'twitter',
    'tiktok',
    'linkedin',
    'apple_podcast',
    'spotify',
    'google_podcast',
    'rss'
);

-- Create social_stats table
CREATE TABLE social_stats (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    podcast_id UUID NOT NULL REFERENCES podcasts(id) ON DELETE CASCADE,
    platform platform_enum NOT NULL,
    
    -- Social platform metrics
    followers INTEGER,
    subscribers INTEGER,
    following INTEGER,
    total_posts INTEGER,
    
    -- Rating and review metrics
    average_rating FLOAT CHECK (average_rating >= 0 AND average_rating <= 5),
    rating_count INTEGER DEFAULT 0,
    
    -- Download metrics (for podcast platforms)
    total_downloads BIGINT,
    monthly_downloads INTEGER,
    
    -- Platform-specific flexible data
    platform_specific_data JSONB DEFAULT '{}',
    
    -- Timestamps
    last_fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(podcast_id, platform)
);

-- Create indexes for better query performance
CREATE INDEX idx_social_stats_podcast_id ON social_stats(podcast_id);
CREATE INDEX idx_social_stats_platform ON social_stats(platform);
CREATE INDEX idx_social_stats_followers ON social_stats(followers);
CREATE INDEX idx_social_stats_subscribers ON social_stats(subscribers);
CREATE INDEX idx_social_stats_average_rating ON social_stats(average_rating);
CREATE INDEX idx_social_stats_last_fetched ON social_stats(last_fetched_at);

-- GIN index for JSONB platform_specific_data
CREATE INDEX idx_social_stats_platform_data ON social_stats USING GIN(platform_specific_data);

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_social_stats_updated_at
    BEFORE UPDATE ON social_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Example insert to test the table structure
-- INSERT INTO social_stats (
--     podcast_id,
--     platform,
--     followers,
--     subscribers,
--     following,
--     total_posts,
--     average_rating,
--     rating_count,
--     total_downloads,
--     monthly_downloads,
--     platform_specific_data
-- ) VALUES (
--     -- Replace with actual podcast_id from podcasts table
--     (SELECT id FROM podcasts LIMIT 1),
--     'youtube',
--     null, -- no followers for YouTube
--     45000, -- subscribers
--     0, -- following
--     156, -- total videos
--     4.7, -- average rating
--     1200, -- rating count
--     null, -- no downloads for YouTube
--     null, -- no monthly downloads for YouTube
--     '{
--         "total_views": 1500000,
--         "avg_view_duration": 180,
--         "subscriber_growth_rate": 5.2,
--         "videos_per_month": 8,
--         "avg_likes_per_video": 350,
--         "avg_comments_per_video": 45
--     }'::jsonb
-- );

-- INSERT INTO social_stats (
--     podcast_id,
--     platform,
--     followers,
--     subscribers,
--     following,
--     total_posts,
--     average_rating,
--     rating_count,
--     total_downloads,
--     monthly_downloads,
--     platform_specific_data
-- ) VALUES (
--     -- Replace with actual podcast_id from podcasts table
--     (SELECT id FROM podcasts LIMIT 1),
--     'instagram',
--     25000, -- followers
--     null, -- no subscribers for Instagram
--     1500, -- following
--     450, -- total posts
--     null, -- no ratings for Instagram
--     null,
--     null, -- no downloads for Instagram
--     null,
--     '{
--         "stories_per_week": 12,
--         "reel_engagement_rate": 8.5,
--         "post_frequency": "daily",
--         "avg_likes_per_post": 850,
--         "avg_comments_per_post": 65,
--         "story_completion_rate": 75
--     }'::jsonb
-- );

-- INSERT INTO social_stats (
--     podcast_id,
--     platform,
--     followers,
--     subscribers,
--     following,
--     total_posts,
--     average_rating,
--     rating_count,
--     total_downloads,
--     monthly_downloads,
--     platform_specific_data
-- ) VALUES (
--     -- Replace with actual podcast_id from podcasts table
--     (SELECT id FROM podcasts LIMIT 1),
--     'spotify',
--     null, -- no followers for Spotify
--     null, -- no subscribers for Spotify
--     null, -- no following for Spotify
--     156, -- episodes count
--     4.8, -- average rating
--     850, -- rating count
--     2500000, -- total downloads
--     125000, -- monthly downloads
--     '{
--         "episodes_count": 156,
--         "completion_rate": 78,
--         "skip_rate": 12,
--         "avg_episode_duration": 1800,
--         "playlist_additions": 5600,
--         "shares": 890
--     }'::jsonb
-- );