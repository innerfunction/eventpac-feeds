# Config JSON file (general.json)

## Styles

- Header : Header CSS (background-color, title size, title color and text-align)
- Description : Content CSS (background-color, text color, font size ...)
- Date : Date CSS (if there is a date)
- Time : Time CSS (if there is a time)
- Image: Image CSS (Speaker photo only, banner/circle shape, inHeader)
- TitleBar : Android titlebar Style (replace views.json value)
- Tabs : Left tabs Style
- List : List style (speaker/event list) 

[Date and time are used only in event detail pages]

## Types

#### Performers, events, pages, locations

- Title : Change the display name
- Styles : Overwrite the main styles with specific CSS


## App images

The location of the application images (sponsorBanner, appIcon, backIcon ...)

# Run the build system 

Within semo-build repo run :
```semoc <module name> [-data <json file>] [-in <in path>] <out path> [-debug]```
