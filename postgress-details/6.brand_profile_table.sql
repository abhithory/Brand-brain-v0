-- Create brand_profiles table
CREATE TABLE brand_profiles (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(500) NOT NULL,
    domain VARCHAR(255),
    logo_url TEXT,
    
    -- Business information
    description TEXT, -- detailed brand story/mission
    category VARCHAR(255), -- primary business category
    subcategory VARCHAR(255), -- more specific category
    industry VARCHAR(255), -- broader industry classification
    
    -- Company details
    revenue_range VARCHAR(50) CHECK (revenue_range IN ('under_1M', '1M-10M', '10M-100M', '100M-1B', '1B+')),
    employee_count_range VARCHAR(50) CHECK (employee_count_range IN ('1-10', '11-50', '51-200', '201-1000', '1000+')),
    company_stage VARCHAR(50) CHECK (company_stage IN ('startup', 'growth', 'enterprise', 'public')),
    founded_year INTEGER CHECK (founded_year >= 1800 AND founded_year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    
    -- Products & Services
    products JSONB DEFAULT '[]', -- Array of product objects
    services JSONB DEFAULT '[]', -- Array of service objects
    
    -- Target audience (fast matching columns)
    target_countries VARCHAR(10)[], -- ["US", "CA", "UK", "AU"]
    target_age_ranges VARCHAR(20)[], -- ["25-34", "35-44", "45-54"]
    target_genders VARCHAR(20)[], -- ["male", "female", "all"]
    target_income_levels VARCHAR(50)[], -- ["50k-75k", "75k-100k", "100k+"]
    primary_target_interests TEXT[], -- ["technology", "business", "entrepreneurship"]
    
    -- Brand identity
    brand_values TEXT[], -- ["innovation", "transparency", "customer-first"]
    brand_personality TEXT[], -- ["professional", "approachable", "cutting-edge"]
    
    -- Detailed target demographics (analytics)
    target_demographics JSONB DEFAULT '{}',
    
    -- Marketing preferences
    preferred_ad_types TEXT[], -- ["brand_awareness", "direct_response", "sponsored_content"]
    budget_range VARCHAR(50) CHECK (budget_range IN ('under_1k', '1k-5k', '5k-20k', '20k-50k', '50k-100k', '100k+')),
    campaign_goals TEXT[], -- ["awareness", "lead_generation", "sales", "thought_leadership"]
    
    -- Contact information (from Apollo or other sources)
    contact_email VARCHAR(255),
    primary_contact_number VARCHAR(255),
    social_links JSONB DEFAULT '{}', -- {"linkedin": "url", "twitter": "url", etc.}
    
    -- Vector embeddings for matching
    brand_embedding vector(1536), -- brand description, values, messaging
    target_audience_embedding vector(1536), -- target demographics and interests
    product_embedding vector(1536), -- products, services, and solutions offered
    content_theme_embedding vector(1536), -- content topics and messaging themes
    
    -- Status and timestamps
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(domain),
    CHECK (name IS NOT NULL AND LENGTH(name) > 0)
);

-- Create indexes for better query performance
CREATE INDEX idx_brand_profiles_name ON brand_profiles(name);
CREATE INDEX idx_brand_profiles_domain ON brand_profiles(domain);
CREATE INDEX idx_brand_profiles_category ON brand_profiles(category);
CREATE INDEX idx_brand_profiles_subcategory ON brand_profiles(subcategory);
CREATE INDEX idx_brand_profiles_industry ON brand_profiles(industry);
CREATE INDEX idx_brand_profiles_company_stage ON brand_profiles(company_stage);
CREATE INDEX idx_brand_profiles_revenue_range ON brand_profiles(revenue_range);
CREATE INDEX idx_brand_profiles_budget_range ON brand_profiles(budget_range);
CREATE INDEX idx_brand_profiles_is_active ON brand_profiles(is_active);
CREATE INDEX idx_brand_profiles_is_verified ON brand_profiles(is_verified);
CREATE INDEX idx_brand_profiles_founded_year ON brand_profiles(founded_year);

-- GIN indexes for arrays and JSONB
CREATE INDEX idx_brand_profiles_target_countries ON brand_profiles USING GIN(target_countries);
CREATE INDEX idx_brand_profiles_target_age_ranges ON brand_profiles USING GIN(target_age_ranges);
CREATE INDEX idx_brand_profiles_target_genders ON brand_profiles USING GIN(target_genders);
CREATE INDEX idx_brand_profiles_target_income_levels ON brand_profiles USING GIN(target_income_levels);
CREATE INDEX idx_brand_profiles_primary_target_interests ON brand_profiles USING GIN(primary_target_interests);
CREATE INDEX idx_brand_profiles_brand_values ON brand_profiles USING GIN(brand_values);
CREATE INDEX idx_brand_profiles_brand_personality ON brand_profiles USING GIN(brand_personality);
CREATE INDEX idx_brand_profiles_preferred_ad_types ON brand_profiles USING GIN(preferred_ad_types);
CREATE INDEX idx_brand_profiles_campaign_goals ON brand_profiles USING GIN(campaign_goals);

-- JSONB indexes
CREATE INDEX idx_brand_profiles_products ON brand_profiles USING GIN(products);
CREATE INDEX idx_brand_profiles_services ON brand_profiles USING GIN(services);
CREATE INDEX idx_brand_profiles_target_demographics ON brand_profiles USING GIN(target_demographics);
CREATE INDEX idx_brand_profiles_social_links ON brand_profiles USING GIN(social_links);

-- Vector similarity indexes
CREATE INDEX idx_brand_profiles_brand_embedding ON brand_profiles USING ivfflat (brand_embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_brand_profiles_target_audience_embedding ON brand_profiles USING ivfflat (target_audience_embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_brand_profiles_product_embedding ON brand_profiles USING ivfflat (product_embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_brand_profiles_content_theme_embedding ON brand_profiles USING ivfflat (content_theme_embedding vector_cosine_ops) WITH (lists = 100);

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_brand_profiles_updated_at
    BEFORE UPDATE ON brand_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Example inserts to test the table structure
-- INSERT INTO brand_profiles (
--     name,
--     domain,
--     logo_url,
--     description,
--     category,
--     subcategory,
--     industry,
--     revenue_range,
--     employee_count_range,
--     company_stage,
--     founded_year,
--     products,
--     services,
--     target_countries,
--     target_age_ranges,
--     target_genders,
--     target_income_levels,
--     primary_target_interests,
--     brand_values,
--     brand_personality,
--     target_demographics,
--     preferred_ad_types,
--     budget_range,
--     campaign_goals,
--     contact_email,
--     primary_contact_number,
--     social_links,
--     is_verified
-- ) VALUES (
--     'TechCorp Solutions',
--     'techcorp.com',
--     'https://techcorp.com/logo.png',
--     'Leading provider of innovative B2B SaaS solutions that help businesses streamline their operations and boost productivity. Our mission is to democratize enterprise-grade technology for businesses of all sizes.',
--     'Software',
--     'B2B SaaS',
--     'Technology',
--     '10M-100M',
--     '201-1000',
--     'growth',
--     2015,
--     '[
--         {
--             "name": "CRM Pro Suite",
--             "category": "Customer Relationship Management",
--             "price_range": "$99-299/month",
--             "target_audience": "small to medium business"
--         },
--         {
--             "name": "Enterprise Analytics Platform",
--             "category": "Business Intelligence",
--             "price_range": "$1000+/month",
--             "target_audience": "enterprise"
--         }
--     ]'::jsonb,
--     '[
--         {
--             "name": "Implementation Consulting",
--             "category": "Professional Services",
--             "typical_engagement": "$10k-50k"
--         },
--         {
--             "name": "Custom Integration",
--             "category": "Technical Services",
--             "typical_engagement": "$5k-25k"
--         }
--     ]'::jsonb,
--     ARRAY['US', 'CA', 'UK', 'AU'],
--     ARRAY['25-34', '35-44', '45-54'],
--     ARRAY['all'],
--     ARRAY['50k-75k', '75k-100k', '100k+'],
--     ARRAY['technology', 'business software', 'productivity', 'CRM', 'analytics'],
--     ARRAY['innovation', 'transparency', 'customer-first', 'reliability'],
--     ARRAY['professional', 'approachable', 'cutting-edge', 'trustworthy'],
--     '{
--         "age_preferences": {
--             "18-24": 5,
--             "25-34": 40,
--             "35-44": 35,
--             "45-54": 15,
--             "55+": 5
--         },
--         "geographic_focus": {
--             "US": 60,
--             "CA": 20,
--             "UK": 15,
--             "AU": 5
--         },
--         "interests_detailed": [
--             {"interest": "B2B software", "priority": "high"},
--             {"interest": "productivity tools", "priority": "high"},
--             {"interest": "business growth", "priority": "medium"},
--             {"interest": "team management", "priority": "medium"}
--         ],
--         "psychographics": {
--             "values": ["efficiency", "innovation", "growth", "collaboration"],
--             "lifestyle": ["professional", "tech-savvy", "busy", "goal-oriented"],
--             "pain_points": ["manual processes", "data silos", "inefficient workflows"]
--         }
--     }'::jsonb,
--     ARRAY['direct_response', 'sponsored_content', 'brand_awareness'],
--     '20k-50k',
--     ARRAY['lead_generation', 'sales', 'thought_leadership'],
--     'marketing@techcorp.com',
--     '+1-555-0123',
--     '{
--         "linkedin": "https://linkedin.com/company/techcorp-solutions",
--         "twitter": "https://twitter.com/techcorpsolutions",
--         "facebook": "https://facebook.com/techcorpsolutions",
--         "website": "https://techcorp.com"
--     }'::jsonb,
--     true
-- );

-- INSERT INTO brand_profiles (
--     name,
--     domain,
--     description,
--     category,
--     subcategory,
--     industry,
--     revenue_range,
--     employee_count_range,
--     company_stage,
--     founded_year,
--     products,
--     target_countries,
--     target_age_ranges,
--     target_genders,
--     target_income_levels,
--     primary_target_interests,
--     brand_values,
--     brand_personality,
--     preferred_ad_types,
--     budget_range,
--     campaign_goals,
--     contact_email
-- ) VALUES (
--     'FitLife Supplements',
--     'fitlifesupplements.com',
--     'Premium health and wellness supplements designed for active professionals. We believe in natural, science-backed nutrition that fits into busy lifestyles.',
--     'Health & Wellness',
--     'Nutritional Supplements',
--     'Consumer Goods',
--     '1M-10M',
--     '11-50',
--     'startup',
--     2020,
--     '[
--         {
--             "name": "Daily Essentials Pack",
--             "category": "Multi-vitamin",
--             "price_range": "$29-49/month",
--             "target_audience": "health-conscious professionals"
--         },
--         {
--             "name": "Performance Pre-Workout",
--             "category": "Sports Nutrition",
--             "price_range": "$39-59/month",
--             "target_audience": "fitness enthusiasts"
--         }
--     ]'::jsonb,
--     ARRAY['US', 'CA'],
--     ARRAY['25-34', '35-44'],
--     ARRAY['male', 'female'],
--     ARRAY['50k-75k', '75k-100k', '100k+'],
--     ARRAY['health', 'fitness', 'wellness', 'nutrition', 'active lifestyle'],
--     ARRAY['natural', 'science-based', 'quality', 'transparency'],
--     ARRAY['energetic', 'motivational', 'authentic', 'health-focused'],
--     ARRAY['affiliate', 'direct_response', 'sponsored_content'],
--     '5k-20k',
--     ARRAY['awareness', 'sales', 'community_building'],
--     'partnerships@fitlifesupplements.com'
-- );

-- Useful queries for testing
-- SELECT 
--     name,
--     category,
--     company_stage,
--     revenue_range,
--     target_countries,
--     primary_target_interests,
--     budget_range
-- FROM brand_profiles 
-- WHERE is_active = true
-- ORDER BY name;

-- -- Query brands by target demographics
-- SELECT 
--     name,
--     primary_target_interests,
--     target_age_ranges,
--     target_countries
-- FROM brand_profiles 
-- WHERE 'technology' = ANY(primary_target_interests)
-- AND 'US' = ANY(target_countries)
-- ORDER BY name;