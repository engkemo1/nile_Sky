import urllib.request
import json
import re

url = 'https://unsplash.com/s/photos/hot-air-balloon-basket'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    html = urllib.request.urlopen(req).read().decode('utf-8')
    # Find image URLs
    urls = re.findall(r'"(https://images\.unsplash\.com/photo-[^"]+\?ixlib=rb-4\.0\.3&amp;q=80&amp;fm=jpg&amp;crop=entropy&amp;cs=tinysrgb&amp;w=1080&amp;fit=max)"', html)
    if urls:
        img_url = urls[0].replace('&amp;', '&')
        print('Downloading:', img_url)
        urllib.request.urlretrieve(img_url, 'c:/Users/kemoe/.gemini/antigravity-ide/scratch/nilesky/customer_app/assets/images/balloon_ride_pov.jpg')
        print('Success')
    else:
        print('No images found on the first attempt, trying a known image ID...')
        img_url = 'https://images.unsplash.com/photo-1507608616759-54f48f0af0ee?ixlib=rb-4.0.3&auto=format&fit=crop&w=1080&q=80'
        urllib.request.urlretrieve(img_url, 'c:/Users/kemoe/.gemini/antigravity-ide/scratch/nilesky/customer_app/assets/images/balloon_ride_pov.jpg')
        print('Success with fallback')
except Exception as e:
    print('Error:', e)
    # Fallback to a known high-quality hot air balloon image
    img_url = 'https://images.unsplash.com/photo-1507608616759-54f48f0af0ee?ixlib=rb-4.0.3&auto=format&fit=crop&w=1080&q=80'
    urllib.request.urlretrieve(img_url, 'c:/Users/kemoe/.gemini/antigravity-ide/scratch/nilesky/customer_app/assets/images/balloon_ride_pov.jpg')
    print('Success with fallback after error')
