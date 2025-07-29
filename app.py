import pandas as pd

# do for 10 shows
from tqdm import tqdm
import time
import difflib
import json
from openai import OpenAI
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
import ast
import tiktoken
import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
from collections import defaultdict
import asyncio


from langchain.text_splitter import CharacterTextSplitter
from langchain.document_loaders import TextLoader
from langchain.docstore.document import Document

from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import TextLoader

from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Chroma

# Initialize OpenAI client
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def get_podcast_details(client_id):
    """
    Get podcast details from 0_pods.csv by clientId
    
    Args:
        client_id (str): The clientId/pod_id to lookup
        
    Returns:
        dict: Dictionary containing podcast name, image, and other details
    """
    try:
        # Load the CSV file
        pods_df = pd.read_csv("0_pods.csv")
        
        # Find the podcast by clientId (id column)
        podcast_row = pods_df[pods_df['id'] == client_id]
        
        if not podcast_row.empty:
            row = podcast_row.iloc[0]
            return {
                'name': row.get('name', 'Unknown Podcast'),
                'image': row.get('image', ''),
                'summary': row.get('summary', ''),
                'categories': row.get('categories', ''),
                'youtube_id': row.get('youtubeID', ''),
                'spotify_id': row.get('spotifyId', ''),
                'website_name': row.get('websiteName', ''),
                'rss_feed': row.get('rssFeed', '')
            }
        else:
            return {
                'name': f'Podcast {client_id}',
                'image': '',
                'summary': 'No details available',
                'categories': '',
                'youtube_id': '',
                'spotify_id': '',
                'website_name': '',
                'rss_feed': ''
            }
    except Exception as e:
        print(f"Error loading podcast details for {client_id}: {e}")
        return {
            'name': f'Podcast {client_id}',
            'image': '',
            'summary': 'Error loading details',
            'categories': '',
            'youtube_id': '',
            'spotify_id': '',
            'website_name': '',
            'rss_feed': ''
        }

def get_podcast_stats(client_id):
    """
    Get podcast advertising stats from pods_stats.csv
    
    Args:
        client_id (str): The clientId to lookup
        
    Returns:
        dict: Dictionary containing advertising metrics
    """
    try:
        # Load the stats CSV file
        stats_df = pd.read_csv("pods_stats.csv")
        
        # Find the podcast stats by clientId
        stats_row = stats_df[stats_df['clientId'] == client_id]
        
        if not stats_row.empty:
            row = stats_row.iloc[0]
            return {
                'min_impressions': row.get('min_impressions', 0),
                'max_impressions': row.get('max_impressions', 0),
                'youtube_subscribers': row.get('youtube_subscribers', 0),
                'instagram_followers': row.get('instagram_followers', 0),
                'episode_avg_views': row.get('episode_avg_views', 0),
                'estimated_ad_price': row.get('estimated_ad_price', 'N/A')
            }
        else:
            return {
                'min_impressions': 0,
                'max_impressions': 0,
                'youtube_subscribers': 0,
                'instagram_followers': 0,
                'episode_avg_views': 0,
                'estimated_ad_price': 'N/A'
            }
    except Exception as e:
        print(f"Error loading podcast stats for {client_id}: {e}")
        return {
            'min_impressions': 0,
            'max_impressions': 0,
            'youtube_subscribers': 0,
            'instagram_followers': 0,
            'episode_avg_views': 0,
            'estimated_ad_price': 'N/A'
        }

def load_podcasts_vector_db():
    embedding = OpenAIEmbeddings()
    pods_stats_db = Chroma(persist_directory="./1_pods_with_stats_embeddings", embedding_function=embedding)
    return pods_stats_db

def get_required_podcast_details_for_brand(brand_details):
    prompt = f"""
You are an expert assistant helping brands find the most suitable podcasts to advertise on.

---

🎯 Objective:
Given a brand’s product, goals, and target audience, generate a detailed profile of the *ideal podcast* where this brand should advertise to maximize relevance, engagement, and return on investment (ROI).

This profile will be used to semantically match against real podcasts in a vector database, so your output must be **high-quality, structured, and JSON-parsable**.

---

🧠 Instructions:
- DO NOT include any actual podcast or brand names.
- DO NOT describe what kind of podcast "would be ideal" — instead, write as if the podcast already exists.
- The podcast summary should be written in the **style of a real podcast description**, like those found on Spotify or Apple Podcasts.
- Make the show feel real — use first/third-person style, include tone, audience, and topics.
- Use only the details provided in the brand input — do not assume or hallucinate beyond that.
- Carefully select podcast categories and stats that align with the brand's size, audience, and goals.
- The value of `"podcast_details_string"` must be a **single JSON-safe string**: all line breaks must be escaped as `\\n`, and all internal quotes must be escaped if needed.
- Use double quotes `"` for all JSON keys and string values.
- Return JSON only — no markdown, no commentary, no code fences

---

📦 Choose only from this list of valid podcast categories:
[
    "technology",
    "business",
    "health&fitness",
    "education",
    "true_crime",
    "news&politics",
    "comedy",
    "sports",
    "kids&family",
    "arts",
    "society&culture",
    "history",
    "fiction",
    "religion&spirituality",
    "leisure",
    "government",
    "music",
    "science",
    "tv&film"
]

---

🧾 Output Format (strictly follow this format):

{{
  "podcast_details_string": "<natural language summary of ideal podcast – audience, tone, topics>
Main Category: <one from the list above>
Subcategories: <comma-separated values from the list above>

YouTube Subscribers: <integer>
Instagram Followers: <integer>
Average Episode Views: <integer>
Impressions Range: <min>-<max>
Estimated Ad Price for 30s: <integer>$
Estimated Ad Price for 60s: <integer>$
Episodes with Ads: <percentage>%
Average Sponsor Length: <seconds>
Ad Percentage Per Episode: <percentage>%
Average Ads Per Episode: <float>
Brand Repeat Rate: <percentage>%
Top Past Sponsors: [<brand1>, <brand2>, ...]"
}}

---

🔍 Brand Details:
{brand_details}
"""

    response = client.responses.create(
        model= "gpt-4o",
        input=prompt,
        temperature=0
    )

    raw_output =  response.output_text.strip()
    # Remove code fences like ```json and ```
    if raw_output.startswith("```"):
        raw_output = raw_output.strip("`")
        raw_output = raw_output.replace("json\n", "").replace("json", "")

    try:
        podcast_matching_string = json.loads(raw_output)
        podcast_details_string = podcast_matching_string["podcast_details_string"]
    except Exception as e:
        print("Exception: ", e)
        podcast_details_string = ""

    return podcast_details_string

def get_enhanced_podcast_results(vector_results):
    """
    Enhance vector search results with podcast details and stats
    
    Args:
        vector_results (list): List of (document, score) tuples from vector search
        
    Returns:
        list: List of enhanced podcast dictionaries
    """
    enhanced_results = []
    
    for doc, score in vector_results:
        # Extract pod_id from metadata (assuming it exists)
        pod_id = doc.metadata.get('pod_id', doc.metadata.get('clientId', doc.metadata.get('id', 'unknown')))
        
        # Get podcast details and stats
        podcast_details = get_podcast_details(pod_id)
        podcast_stats = get_podcast_stats(pod_id)
        
        enhanced_result = {
            'pod_id': pod_id,
            'similarity_score': score,
            'content': doc.page_content,
            'metadata': doc.metadata,
            'name': podcast_details['name'],
            'image': podcast_details['image'],
            'summary': podcast_details['summary'],
            'categories': podcast_details['categories'],
            'youtube_id': podcast_details['youtube_id'],
            'spotify_id': podcast_details['spotify_id'],
            'website_name': podcast_details['website_name'],
            'rss_feed': podcast_details['rss_feed'],
            'min_impressions': podcast_stats['min_impressions'],
            'max_impressions': podcast_stats['max_impressions'],
            'youtube_subscribers': podcast_stats['youtube_subscribers'],
            'instagram_followers': podcast_stats['instagram_followers'],
            'episode_avg_views': podcast_stats['episode_avg_views'],
            'estimated_ad_price': podcast_stats['estimated_ad_price']
        }
        
        enhanced_results.append(enhanced_result)
    
    return enhanced_results

def search_for_podcasts(brand_details):
    """
    Search for podcasts based on brand details and return enhanced results
    
    Args:
        brand_details (dict): Dictionary containing brand information including:
            - website: str
            - budget: int
            - aov: int  
            - ctr: float
            - target_gender: str
            - target_hhi: str
            - interests: list
    
    Returns:
        list: List of enhanced podcast dictionaries with names, images, and stats
    """
    llm_result_string_for_brand = get_required_podcast_details_for_brand(brand_details)
    pods_stats_db = load_podcasts_vector_db()
    vector_results = pods_stats_db.similarity_search_with_score(
        llm_result_string_for_brand,
        k=5  # or however many top matches you want
    )
    
    # Enhance results with podcast details and stats
    enhanced_results = get_enhanced_podcast_results(vector_results)
    
    print(f"Found {len(enhanced_results)} enhanced podcast recommendations")
    return enhanced_results

    