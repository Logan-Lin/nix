{
  force = true;
  default = "ddg";
  
  engines = {
    # Hide unwanted default search engines
    "google".metaData.hidden = true;
    "bing".metaData.hidden = true;
    "amazondotcom-us".metaData.hidden = true;
    "ebay".metaData.hidden = true;
    "wikipedia".metaData.hidden = true;
  };
}
