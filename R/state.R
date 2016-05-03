
library(dplyr, warn.conflicts = FALSE)
library(maptools)

# Download US state shape files ------------------------------------------

url = "http://www2.census.gov/geo/tiger/GENZ2010/gz_2010_us_040_00_20m.zip"
fil = "data-raw/gz_2010_us_040_00_20m.zip"
if (!file.exists(fil)) downloader::download(url, fil)
unzip(fil, exdir = "data-raw")
list.files("data-raw")

# Load the shape files ----------------------------------------------------

state = rgdal::readOGR("data-raw", "gz_2010_us_040_00_20m")
original_proj = state %>% sp::proj4string()
albers_proj = "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"

# Hawaii ------------------------------------------------------------------

hawaii = state[state@data$STATE == "15", ]
hawaii$fips = hawaii$STATE
hawaii %>%
        sp::spTransform(sp::CRS(albers_proj)) %>%
        maptools::elide(rotate = -35) %>%
        maptools::elide(shift = c(5400000, -1400000)) ->
        hawaii
sp::proj4string(hawaii) = albers_proj
hawaii %>%
        sp::spTransform(sp::CRS(original_proj)) %>%
        broom::tidy(region = "fips") %>%
        tbl_df() ->
        hawaii

# Alaska ------------------------------------------------------------------

alaska = state[state@data$STATE == "02", ]
alaska$fips = alaska$STATE
alaska %>%
        sp::spTransform(sp::CRS(albers_proj)) %>%
        maptools::elide(rotate = -50) %>%
        maptools::elide(scale = max(apply(sp::bbox(.), 1, diff)) / 2.3) %>%
        maptools::elide(shift = c(-2100000, -2500000)) ->
        alaska
sp::proj4string(alaska) = albers_proj
alaska %>%
        sp::spTransform(sp::CRS(original_proj)) %>%
        broom::tidy(region = "fips") %>%
        tbl_df() ->
        alaska

# Full state data --------------------------------------------------------

state = state[!(state@data$STATE %in% c("02", "15", "72")), ]
state$fips = state$STATE
state %>%
        broom::tidy(region = "fips") %>%
        bind_rows(hawaii) %>%
        bind_rows(alaska) %>%
        tbl_df() ->
        state

# Save --------------------------------------------------------------------

devtools::use_data(state, overwrite = TRUE)

# Delete source files but keep the zip files ------------------------------

system("rm `find data-raw -name 'gz_2010_us_040_00_20m.*' -a ! -name '*.zip'`")
unlink(fil)
