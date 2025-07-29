-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- Create podcasts table
CREATE TABLE podcasts (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firestore_id VARCHAR(255) UNIQUE,
    
    -- Basic podcast information
    name VARCHAR(500) NOT NULL,
    description TEXT,
    category VARCHAR(255),
    subcategory VARCHAR(255),
    rss_feed_url TEXT,
    
    -- Social links as JSONB
    social_links JSONB DEFAULT '{}',
    
    -- Geographic and language data
    primary_countries VARCHAR(10)[], -- Array of country codes like ["US", "CA", "UK"]
    language VARCHAR(10) DEFAULT 'en',
    
    -- Audience demographics (fast matching columns)
    dominant_age_range VARCHAR(20), -- "25-34", "35-44", "18-24", "45-54", "55+"
    male_percentage FLOAT CHECK (male_percentage >= 0 AND male_percentage <= 100),
    female_percentage FLOAT CHECK (female_percentage >= 0 AND female_percentage <= 100),
    other_gender_percentage FLOAT CHECK (other_gender_percentage >= 0 AND other_gender_percentage <= 100),
    
    -- Top interests for quick matching
    top_3_interests TEXT[], -- ["technology", "business", "fitness"]
    
    -- Detailed demographics as JSONB
    audience_demographics JSONB DEFAULT '{}',
    
    -- Vector embeddings for semantic matching
    content_embedding vector(1536), -- OpenAI embedding dimension
    audience_embedding vector(1536), -- Audience profile embedding
    
    -- Timestamp
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Data integrity constraints
    CONSTRAINT valid_gender_percentages CHECK (
        (male_percentage + female_percentage + other_gender_percentage) <= 100
    )
);

-- Create indexes for better query performance
CREATE INDEX idx_podcasts_category ON podcasts(category);
CREATE INDEX idx_podcasts_subcategory ON podcasts(subcategory);
CREATE INDEX idx_podcasts_language ON podcasts(language);
CREATE INDEX idx_podcasts_dominant_age_range ON podcasts(dominant_age_range);
CREATE INDEX idx_podcasts_primary_countries ON podcasts USING GIN(primary_countries);
CREATE INDEX idx_podcasts_top_3_interests ON podcasts USING GIN(top_3_interests);

-- Vector similarity indexes (using IVFFlat for faster similarity search)
CREATE INDEX idx_podcasts_content_embedding ON podcasts USING ivfflat (content_embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_podcasts_audience_embedding ON podcasts USING ivfflat (audience_embedding vector_cosine_ops) WITH (lists = 100);

-- Create trigger function for updating updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_podcasts_updated_at
    BEFORE UPDATE ON podcasts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Example insert to test the table structure
-- INSERT INTO podcasts (
--     firestore_id,
--     name,
--     description,
--     category,
--     subcategory,
--     primary_countries,
--     language,
--     dominant_age_range,
--     male_percentage,
--     female_percentage,
--     other_gender_percentage,
--     top_3_interests,
--     audience_demographics,
--     social_links
-- ) VALUES (
--     'firestore_123',
--     'Tech Talk Weekly',
--     'A weekly podcast discussing the latest in technology and innovation',
--     'Technology',
--     'Software Development',
--     ARRAY['US', 'CA', 'UK'],
--     'en',
--     '25-34',
--     65.0,
--     30.0,
--     5.0,
--     ARRAY['technology', 'software', 'innovation'],
--     '{
--         "age_breakdown": {
--             "18-24": 15,
--             "25-34": 45,
--             "35-44": 25,
--             "45-54": 12,
--             "55+": 3
--         },
--         "country_breakdown": {
--             "US": 60,
--             "CA": 25,
--             "UK": 15
--         },
--         "interests_detailed": [
--             {"interest": "technology", "percentage": 90},
--             {"interest": "software development", "percentage": 75},
--             {"interest": "innovation", "percentage": 80}
--         ],
--         "income_levels": {
--             "under_25k": 5,
--             "25k_50k": 15,
--             "50k_75k": 30,
--             "75k_100k": 30,
--             "100k_150k": 15,
--             "150k_plus": 5
--         },
--         "education": {
--             "high_school": 10,
--             "some_college": 20,
--             "bachelors": 50,
--             "masters": 18,
--             "phd": 2
--         }
--     }'::jsonb,
--     '{
--         "instagram": "https://instagram.com/techtalkweekly",
--         "youtube": "https://youtube.com/techtalkweekly",
--         "twitter": "https://twitter.com/techtalkweekly"
--     }'::jsonb
-- );