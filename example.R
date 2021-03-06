# Import neccessary libraries
library(ggplot2)
library(data.table)

# no one in Norway is infected, and everyone is susceptible
spread::norway_seiiar_noinfected_2017_b2020

# 10 people in Oslo are infected, and everyone is susceptible
spread::norway_seiiar_oslo_2017_b2020

# no one in Norway is infected, and childhood vaccination data is used to
# estimate the number of "recovered" (i.e. non-susceptible) people for measles
spread::norway_seiiar_measles_noinfected_2017_b2020

# 10 people in Oslo is infected, and childhood vaccination data is used to
# estimate the number of "recovered" (i.e. non-susceptible) people for measles
spread::norway_seiiar_measles_oslo_2017_b2020

# we can take a closer look at Oslo
spread::norway_seiiar_measles_oslo_2017_b2020[location_code=="municip0301"]


# we provide the number of municipal commuters in Norway in 2017
spread::norway_commuters_2017_b2020

# We simulate one measles outbreak using the datasets spread::norway_seiiar_measles_oslo_2017_b2020 and spread::norway_commuters_2017_b2020: 
set.seed(4)
d <- spread::commuter(
  seiiar=spread::norway_seiiar_measles_oslo_2017_b2020,
  commuters=spread::norway_commuters_2017_b2020,
  r0=14,
  latent_period = 8,
  infectious_period = 5,
  asymptomatic_prob=0,
  asymptomatic_relative_infectiousness=0,
  days_simulation=7*9,
  N=1
)


# We can merge in information about counties, and create county level data:

d[location_code=="municip0301"]

d <- merge(d,fhidata::norway_locations_b2020, by.x="location_code",by.y="municip_code")
county <- d[,.(
  S=sum(S),
  E=sum(E),
  I=sum(I),
  Ia=sum(Ia),
  R=sum(R),
  incidence=sum(incidence),
  pop=sum(pop)
),
keyby=.(county_code,county_name,week,day,is_6pm)]
county[,county_name:=factor(county_name,levels=unique(fhidata::norway_locations_b2020[,c("county_code","county_name")]$county_name))]
county


# We can produce a daily epicurve for each county:
p <- ggplot(county, aes(x=day, y=incidence))
p <- p + geom_col()
p <- p + facet_wrap(~county_name)
p <- p + scale_x_continuous("Day")
p


# And we can produce weekly maps:
w <- county[,.(
  incidence_weekly = sum(incidence),
  pop = mean(pop)
), keyby=.(county_code, week)]

w[,weekly_incidence_per_10000 := 10000*incidence_weekly/pop]
w[,facet:=glue::glue("Week {week}",week=week)]
w

pd <- merge(
  w,
  fhimaps::norway_nuts3_map_b2020_default_dt, 
  by.x="county_code",
  by.y="location_code",
  allow.cartesian = T)

p <- ggplot(data=pd, mapping=aes( x = long, y = lat, group = group))
p <- p + geom_polygon(aes(fill=weekly_incidence_per_10000))
p <- p + facet_wrap(~facet)
p <- p + theme_void()
p <- p + coord_quickmap()
p
ggsave("plot_example.png")