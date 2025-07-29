-- Create episode type enum
CREATE TYPE episode_type_enum AS ENUM (
    'youtube',
    'spotify', 
    'apple',
    'rss',
    'other'
);

-- Create episodes table
CREATE TABLE episodes (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    podcast_id UUID NOT NULL REFERENCES podcasts(id) ON DELETE CASCADE,
    source_id VARCHAR(255) NOT NULL,
    type episode_type_enum NOT NULL,
    
    -- Basic episode information
    title VARCHAR(1000) NOT NULL,
    description TEXT,
    published_at TIMESTAMP NOT NULL,
    duration INTEGER, -- in seconds
    
    -- Content URLs
    transcript_url TEXT,
    audio_url TEXT,
    
    -- Engagement metrics
    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    dislikes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    
    -- Content analysis
    transcript_analysis JSONB DEFAULT '{}',
    topics TEXT[], -- extracted topics/keywords
    guest_names TEXT[], -- if interview format
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(podcast_id, source_id, type),
    CHECK (duration > 0 OR duration IS NULL),
    CHECK (views >= 0),
    CHECK (likes >= 0),
    CHECK (dislikes >= 0),
    CHECK (comments >= 0),
    CHECK (shares >= 0)
);

-- Create indexes for better query performance
CREATE INDEX idx_episodes_podcast_id ON episodes(podcast_id);
CREATE INDEX idx_episodes_type ON episodes(type);
CREATE INDEX idx_episodes_published_at ON episodes(published_at DESC);
CREATE INDEX idx_episodes_source_id ON episodes(source_id);
CREATE INDEX idx_episodes_views ON episodes(views DESC);
CREATE INDEX idx_episodes_likes ON episodes(likes DESC);
CREATE INDEX idx_episodes_duration ON episodes(duration);

-- GIN indexes for arrays and JSONB
CREATE INDEX idx_episodes_topics ON episodes USING GIN(topics);
CREATE INDEX idx_episodes_guest_names ON episodes USING GIN(guest_names);
CREATE INDEX idx_episodes_transcript_analysis ON episodes USING GIN(transcript_analysis);

-- Composite index for common queries
CREATE INDEX idx_episodes_podcast_published ON episodes(podcast_id, published_at DESC);
CREATE INDEX idx_episodes_podcast_type ON episodes(podcast_id, type);

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_episodes_updated_at
    BEFORE UPDATE ON episodes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Example inserts to test the table structure
-- INSERT INTO episodes (
--     podcast_id,
--     source_id,
--     type,
--     title,
--     description,
--     published_at,
--     duration,
--     transcript_url,
--     audio_url,
--     views,
--     likes,
--     dislikes,
--     comments,
--     shares,
--     transcript_analysis,
--     topics,
--     guest_names
-- ) VALUES (
--     -- Replace with actual podcast_id from podcasts table
--     (SELECT id FROM podcasts LIMIT 1),
--     'dQw4w9WgXcQ', -- YouTube video ID example
--     'youtube',
--     'The Future of AI in Business - Expert Interview',
--     'In this episode, we dive deep into how artificial intelligence is transforming modern business practices with industry expert John Smith.',
--     '2024-01-15 10:00:00',
--     2340, -- 39 minutes in seconds
--     'https://example.com/transcripts/episode-123.txt',
--     'https://example.com/audio/episode-123.mp3',
--     15420, -- views
--     892, -- likes
--     23, -- dislikes
--     156, -- comments
--     78, -- shares
--     '{
--         "sentiment_score": 0.85,
--         "key_phrases": ["artificial intelligence", "business transformation", "machine learning"],
--         "entities": ["John Smith", "OpenAI", "Microsoft"],
--         "summary": "Discussion about AI impact on business operations and future trends",
--         "language_confidence": 0.98
--     }'::jsonb,
--     ARRAY['artificial intelligence', 'business', 'technology', 'machine learning', 'automation'],
--     ARRAY['John Smith', 'AI Expert']
-- );

-- INSERT INTO episodes (
--     podcast_id,
--     source_id,
--     type,
--     title,
--     description,
--     published_at,
--     duration,
--     views,
--     likes,
--     comments,
--     transcript_analysis,
--     topics,
--     guest_names
-- ) VALUES (
--     -- Replace with actual podcast_id from podcasts table
--     (SELECT id FROM podcasts LIMIT 1),
--     'spotify:episode:4rOoJ6Egrf8K2IrywzwOMk', -- Spotify episode ID example
--     'spotify',
--     'Startup Funding Strategies in 2024',
--     'Solo episode discussing the current landscape of startup funding and what entrepreneurs need to know.',
--     '2024-01-10 08:00:00',
--     1980, -- 33 minutes in seconds
--     8500, -- plays/views
--     234, -- likes
--     45, -- comments
--     '{
--         "sentiment_score": 0.72,
--         "key_phrases": ["startup funding", "venture capital", "seed rounds"],
--         "entities": ["Y Combinator", "Andreessen Horowitz", "Series A"],
--         "summary": "Overview of current funding landscape and strategies for startups",
--         "language_confidence": 0.96
--     }'::jsonb,
--     ARRAY['startups', 'funding', 'venture capital', 'entrepreneurship', 'business'],
--     ARRAY[] -- no guests, solo episode
-- );

-- INSERT INTO episodes (
--     podcast_id,
--     source_id,
--     type,
--     title,
--     description,
--     published_at,
--     duration,
--     transcript_url,
--     audio_url,
--     topics
-- ) VALUES (
--     -- Replace with actual podcast_id from podcasts table
--     (SELECT id FROM podcasts LIMIT 1),
--     'rss-item-guid-12345', -- RSS item GUID
--     'rss',
--     'Weekly Tech News Roundup',
--     'Our weekly roundup of the most important tech news and developments.',
--     '2024-01-08 12:00:00',
--     1620, -- 27 minutes in seconds
--     'https://podcast.example.com/transcripts/weekly-roundup-jan-8.txt',
--     'https://podcast.example.com/audio/weekly-roundup-jan-8.mp3',
--     ARRAY['technology', 'news', 'weekly roundup', 'tech industry', 'updates']
-- );