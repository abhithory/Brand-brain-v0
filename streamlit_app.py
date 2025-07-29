import streamlit as st
import pandas as pd
import os
from dotenv import load_dotenv
from app import search_for_podcasts, get_required_podcast_details_for_brand

# Load environment variables
load_dotenv()

st.set_page_config(
    page_title="BrandBrain - Podcast Advertising Recommendations",
    page_icon="🎙️",
    layout="wide"
)

st.title("🎙️ BrandBrain - Podcast Advertising Recommendations")
st.markdown("Find the perfect podcasts to advertise your brand based on your target audience and budget.")

st.markdown("---")

# Create form for brand details input
with st.form("brand_details_form"):
    st.subheader("📋 Brand Details")
    
    col1, col2 = st.columns(2)
    
    with col1:
        website = st.text_input(
            "Website URL", 
            value="vimergy.com",
            help="Your brand's website (with or without https://)"
        )
        
        budget = st.number_input(
            "Campaign Budget ($)", 
            min_value=1000, 
            max_value=1000000, 
            value=40000,
            step=1000,
            help="Total advertising budget for this campaign"
        )
        
        aov = st.number_input(
            "AOV - Average Order Value ($)", 
            min_value=10, 
            max_value=1000, 
            value=80,
            step=5,
            help="Average amount customers spend per order"
        )
    
    with col2:
        ctr = st.number_input(
            "CTR - Click Through Rate (%)", 
            min_value=0.1, 
            max_value=10.0, 
            value=1.5,
            step=0.1,
            format="%.2f",
            help="Expected click-through rate for your ads"
        )
        
        target_gender = st.slider(
            "Target Gender (% Female)", 
            min_value=0, 
            max_value=100, 
            value=90,
            help="Percentage of target audience that is female"
        )
        
        hhi = st.selectbox(
            "Target HHI (Household Income)",
            options=[
                "Under $25k",
                "$25k-$50k", 
                "$50k-$75k",
                "$75k-$100k",
                "$100k+",
                "$150k+",
                "$200k+"
            ],
            index=4,
            help="Target household income bracket"
        )
    
    # Additional brand interests/categories
    st.subheader("🎯 Brand Categories (Optional)")
    interests = st.text_area(
        "Brand Interests/Categories",
        value="Holistic Health & Wellness, Clean Eating & Gut Health, Functional & Integrative Medicine",
        help="Comma-separated list of your brand's main categories or interests"
    )
    
    submitted = st.form_submit_button("🔍 Find Recommended Podcasts", type="primary")

# Process form submission
if submitted:
    # Validate inputs
    if not website:
        st.error("Please enter a website URL")
    elif budget <= 0:
        st.error("Please enter a valid budget")
    elif aov <= 0:
        st.error("Please enter a valid AOV")
    else:
        # Format website URL
        if not website.startswith(('http://', 'https://')):
            website = f"https://{website}"
        
        # Create brand details dictionary
        brand_details = {
            "website": website,
            "budget": budget,
            "aov": aov,
            "ctr": ctr,
            "target_gender": f"{target_gender}% female",
            "target_hhi": hhi,
            "interests": [interest.strip() for interest in interests.split(",") if interest.strip()]
        }
        
        # Display processing message
        with st.spinner("🤖 Analyzing your brand and finding the best podcast matches..."):
            try:
                # Get podcast recommendations
                results = search_for_podcasts(brand_details)
                
                st.success(f"✅ Found {len(results)} podcast recommendations!")
                
                # Display results
                if results:
                    st.markdown("---")
                    st.subheader("🎙️ Recommended Podcasts")
                    
                    for i, podcast in enumerate(results, 1):
                        # Create a container for each podcast recommendation
                        with st.container():
                            st.markdown(f"### #{i} - {podcast['name']}")
                            
                            # Create columns for image and details
                            col1, col2, col3 = st.columns([1, 2, 2])
                            
                            with col1:
                                # Display podcast image
                                if podcast['image'] and podcast['image'].strip():
                                    try:
                                        st.image(podcast['image'], width=150, caption=podcast['name'])
                                    except:
                                        st.markdown("🎙️ *No image available*")
                                else:
                                    st.markdown("🎙️ *No image available*")
                            
                            with col2:
                                # Basic podcast info
                                st.markdown("**📊 Match Quality**")
                                similarity_percent = (1 - podcast['similarity_score']) * 100
                                st.progress(similarity_percent / 100)
                                st.write(f"Similarity Score: {similarity_percent:.1f}%")
                                
                                st.markdown("**📝 Description**")
                                if podcast['summary']:
                                    st.write(podcast['summary'][:200] + "..." if len(podcast['summary']) > 200 else podcast['summary'])
                                else:
                                    st.write("No description available")
                                
                                # Categories
                                if podcast['categories']:
                                    st.markdown("**🏷️ Categories**")
                                    try:
                                        # Parse categories if it's a JSON string
                                        import ast
                                        if isinstance(podcast['categories'], str) and podcast['categories'].startswith('['):
                                            categories = ast.literal_eval(podcast['categories'])
                                            st.write(", ".join(categories))
                                        else:
                                            st.write(podcast['categories'])
                                    except:
                                        st.write(podcast['categories'])
                            
                            with col3:
                                # Advertising metrics
                                st.markdown("**💰 Advertising Metrics**")
                                
                                # Format numbers nicely
                                def format_number(num):
                                    if num >= 1000000:
                                        return f"{num/1000000:.1f}M"
                                    elif num >= 1000:
                                        return f"{num/1000:.1f}K"
                                    else:
                                        return str(int(num))
                                
                                if podcast['youtube_subscribers'] > 0:
                                    st.metric("YouTube Subscribers", format_number(podcast['youtube_subscribers']))
                                
                                if podcast['instagram_followers'] > 0:
                                    st.metric("Instagram Followers", format_number(podcast['instagram_followers']))
                                
                                if podcast['episode_avg_views'] > 0:
                                    st.metric("Avg Episode Views", format_number(podcast['episode_avg_views']))
                                
                                # Impressions range
                                if podcast['min_impressions'] > 0 and podcast['max_impressions'] > 0:
                                    st.metric("Impressions Range", 
                                             f"{format_number(podcast['min_impressions'])}-{format_number(podcast['max_impressions'])}")
                                
                                # Ad pricing
                                if podcast['estimated_ad_price'] != 'N/A':
                                    st.markdown("**💵 Estimated Ad Prices**")
                                    st.write(f"📺 {podcast['estimated_ad_price']}")
                            
                            # Expandable section for more details
                            with st.expander("📋 View Detailed Analysis & Raw Data"):
                                st.markdown("**🔍 AI Analysis Content:**")
                                st.text_area("Vector Search Match Content", 
                                           podcast['content'], 
                                           height=100, 
                                           key=f"content_{i}")
                                
                                # Platform links
                                col_yt, col_spotify = st.columns(2)
                                with col_yt:
                                    if podcast['youtube_id']:
                                        st.markdown(f"🎥 [YouTube Channel](https://youtube.com/channel/{podcast['youtube_id']})")
                                
                                with col_spotify:
                                    if podcast['spotify_id']:
                                        st.markdown(f"🎵 [Spotify Podcast](https://open.spotify.com/show/{podcast['spotify_id']})")
                                
                                # Raw metadata
                                if podcast['metadata']:
                                    st.markdown("**🔧 Technical Metadata:**")
                                    st.json(podcast['metadata'])
                            
                            st.markdown("---")
                
                else:
                    st.warning("No podcast recommendations found. Try adjusting your criteria.")
                    
            except Exception as e:
                st.error(f"An error occurred while processing your request: {str(e)}")
                st.info("Please check your OpenAI API key and ChromaDB setup.")
                # Show error details for debugging
                import traceback
                st.code(traceback.format_exc())

# Sidebar with information
with st.sidebar:
    st.markdown("### ℹ️ How it works")
    st.markdown("""
    1. **Enter your brand details** - website, budget, target audience
    2. **AI analyzes your brand** - creates an ideal podcast profile
    3. **Vector search** - finds matching podcasts in our database
    4. **Get recommendations** - ranked by relevance and fit
    """)
    
    st.markdown("### 📊 What you'll get")
    st.markdown("""
    - Podcast audience demographics
    - Advertising costs and metrics  
    - Similar past sponsors
    - Episode statistics
    - Contact information
    """)
    
    st.markdown("---")
    st.markdown("*Powered by ChromaDB & OpenAI*")