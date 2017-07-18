# -*- coding: utf-8 -*-
"""
Created on Sat Nov 12 13:19:47 2016

"""

from bs4 import BeautifulSoup as bs
import requests
import time
import csv
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

url = 'http://www.apartments.com/washington-dc/' # URL to be scrape from


def getData(url):
    """
    Input: Dictionary containing URLs of first result page
    Output: Two csv files summarizing the data from results
    Returns: Nothing
    """
    
    apartments = []
    i = 0 # Key to identify restaurants
    pages = range(1,29)   # Range of strings to add to URL to go to next result page
    amenities = ['Dogs', 'Cats','AC','Washer-Dryer','Dishwasher','Parking','Gym','Wheelchair']
    
    
    for page in pages:   # Get results one page at a time
        time.sleep(0.1)
        url1 = url+str(page)+'/'  # URL to search
        request = requests.get(url1)
        html = request.text
        soup = bs(html,"html.parser")    
        results1 = soup.findAll('article', {"class" : "diamond placard"})
        results2 = soup.findAll('article', {"class" : "platinum placard"})
        results3 = soup.findAll('article', {"class" : "gold placard"})
        results4 = soup.findAll('article', {"class" : "silver placard"})
        results5 = soup.findAll('article', {"class" : "prosumer placard"})
        results6 = soup.findAll('article', {"class" : "basic placard"})
        results = results1 + results2 + results3 + results4 + results5 + results6

        for result in results:  
            apartments.append({})  
            apt_name = result.findAll('a', {"class" : "placardTitle js-placardTitle"})
            apartments[i]['Name'] = apt_name[0].getText()
            address = result.findAll('div', {"class" : "location"})
            address = address[0].getText()
            splits = address.split(',')
            if len(splits) > 2:
                apartments[i]['Address'] = splits[0]
                apartments[i]['City'] = splits[1]
                apartments[i]['State'] = splits[2].split()[0]
                apartments[i]['Zip'] = splits[2].split()[1]
            else:
                apartments[i]['Address'] = apt_name[0].getText()
                apartments[i]['City'] = splits[0]
                apartments[i]['State'] = splits[1].split()[0]
                apartments[i]['Zip'] = splits[1].split()[1]
            
            last_update = result.findAll('span', {"class" : "listingFreshness"})
            apartments[i]['Last update'] = last_update[0].getText().strip()            
            images = result.findAll('span', {"class" : "js-spnImgCount"})
            if len(images) > 0:
                apartments[i]['Image count'] = images[0].getText()
            else:
                apartments[i]['Image count'] = 'Not specified'
    
            price = result.findAll('span', {"class" : "altRentDisplay"})
            apartments[i]['Rent'] = price[0].getText().replace('$','')
            
            style = result.findAll('span', {"class" : "unitLabel propertyStyle"})
            if len(style) == 0:
                style = result.findAll('span', {"class" : "unitLabel"})
                if 'Studio' in style[0].getText():
                    apartments[i]['Style'] = 'Studio'
                    if len(style[0].getText().split()) < 2:
                        apartments[i]['Num bedrooms'] = 1
                    else:
                        if '-' in style[0].getText().split()[2]:                  
                            apartments[i]['Num bedrooms'] = style[0].getText().split()[2].split('-')[1]
                        else:
                            apartments[i]['Num bedrooms'] = style[0].getText().split()[2]
                else:
                    apartments[i]['Style'] = 'Apartment'
                    if '-' in style[0].getText():
                        apartments[i]['Num bedrooms'] = style[0].getText().split()[0].split('-')[1]
                    else:
                        apartments[i]['Num bedrooms'] = style[0].getText().split()[0]
            else:
                apartments[i]['Style'] = style[0].getText()
                apartments[i]['Num bedrooms'] = 'N/A'
            
            amenities_results = {}
            if (len(result.findAll('ul', {"class" : "amenities"}))) > 0:
                apartments[i]['Amenities'] = {}
                amenities_results['Dogs'] = result.findAll('li', {"class" : "petIcon"})
                amenities_results['Cats'] = result.findAll('li', {"class" : "catIcon"})
                amenities_results['AC'] = result.findAll('li', {"class" : "airConditionerIcon"})
                amenities_results['Washer-Dryer'] = result.findAll('li', {"class" : "laundryIcon"})
                amenities_results['Dishwasher'] = result.findAll('li', {"class" : "dishWasherIcon"})
                amenities_results['Parking'] = result.findAll('li', {"class" : "carIcon"})
                amenities_results['Gym'] = result.findAll('li', {"class" : "fitnessIcon"})
                amenities_results['Wheelchair'] = result.findAll('li', {"class" : "wheelchairIcon"})   
                for amenity in amenities:
                    if (len(amenities_results[amenity]) > 0) :                   
                        apartments[i]['Amenities'][amenity] = True
                    else:
                        apartments[i]['Amenities'][amenity] = False
            else:
                apartments[i]['Amenities'] = 'Not listed'

                
            i+=1
    return apartments
"""
    with open('apartments.csv', 'w', newline = '') as file1:
        fieldnames = ['Name','Address','City','State','Zip','Last update','Image count','Num bedrooms','Rent','Amenities']
        writer = csv.DictWriter(file1, fieldnames=fieldnames)
        writer.writeheader()
        for keyname in apartments:
            writer.writerow(apartments[keyname])
"""

