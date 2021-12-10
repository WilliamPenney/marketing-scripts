require 'colorize'
require 'open-uri'
require 'csv'
require 'nokogiri'

QUALITY_WILLINGNESS = 0.05


def load_offerings(min_speed = "LTE")
	file = open('telna_rates.csv')
	offerings = CSV.open(file, { col_sep: ';' }).to_a
	offerings.each_with_index do |r, i|
		# remove 'IMSI ' from IMSIP column
		offerings[i][2] = r[2].split(' ').last.to_i
		# convert rate to float
		offerings[i][4] = offerings[i][4].to_f
	end
	# select LTE only
	offerings = offerings.select { |op| fastest_speed(op) == "LTE" }
end




def fastest_speed(op)
	if    op[-2] == "true"
		"LTE"
	elsif op[-3] == "true" 
		"3G"
	elsif op[-4] == "true"
		"2G"
	end
end

def breakage_lookup(size)
	case size
		when  1 then 0.05
		when  3 then 0.10
		when  5 then 0.15
		when 10 then 0.20
	end
end

def manual_prices
	lookup = Hash.new

	# set fixed pricing
	lookup['USA'] 			 = { 1 => 5, 3 => 12, 5 => 20, 10 => 32 }
	lookup['Bulgaria'] 		 = { 3 => 5   }
	lookup['Czech Republic'] = { 3 => 12  }
	lookup['South Korea'] 	 = { 3 => 10  }
	lookup['Vietnam Korea']  = { 1 => 10  }

	# suppress pricing
	lookup['Philippines'] 	 = { 3 => nil, 5 => nil, 10 => nil }
	lookup['Israel'] 		 = { 3 => nil }

	lookup
end


def airalo_unlimited_countries(airalo_packages)
	airalo_packages.select { |r| r[3] == 'Unlimited' }.map { |r| r[0] }.uniq
end


def imsip_home_region_lookup(imsip) # NOT USED ANYMORE
	case imsip
		when 2 then 'Caribbean'
		when 10 then 'Asia'
		when 22 then 'South America'
		when 25 then 'Europe'
		when 26 then 'North America'
	end
end


def region_pgw_loc(region)
	case region
		# regions with direct mapping to PGW
		when 'Caribbean' then 'USA'
		when 'Central America' then 'USA'
		when 'North America' then 'USA'
		when 'South America' then 'USA'
		when 'Europe' then 'Europe'
		when 'Asia' then 'Singapore'
		# regions that will use lowest cost routing to PGW
		when 'Africa' then nil
		when 'Middle East' then nil
		when 'Oceania' then nil
	end
end

def imsip_pgw_loc(imsip)
	case imsip
		when 2 then 'USA'
		when 22 then 'USA'
		when 26 then 'USA'
		when 10 then 'Singapore'
		when 25 then 'Europe'
	end
end

def regional_routing?(op)
	region = op[0]
	imsip  = op[2]
	if region_pgw_loc(region).nil?
		# no PGW found for this region; lowest cost routing will be used
		false
	else
		loc_a = region_pgw_loc(region)
		loc_b = imsip_pgw_loc(imsip)
		loc_a == loc_b
	end
end

def manual_routing(country)
	case country
		when 'Uruguay' then  2  # 2 / 10 / 22 but 2 is cheapest
		when 'Liberia' then  2  # USA or USA 			[2, 22]... should be the same latency
		when 'Egypt'   then 10 	# USA or Singapore 		[2, 10]
		when 'Qatar'   then 10 	# USA or Singapore 		[22, 10]?
		when 'Vanuatu' then 10 	# Europe or Singapore 	[25, 10]?
		else nil
	end
end

def lookup_competing_price(airalo_packages, country, size, duration)
	# translate country name from telna to airalo
	airalo_country = translate_telna_country_to_airalo(country)
	# find and return first match
	airalo_packages.find { |a| a.first == airalo_country and a[3].to_f.round(1) == size and a[4].to_i == duration}
end


def duration_lookup(size)
	case size # in Gigabytes
		when 1.0 then 7 # days
		when 3.0 then 30 # days
		when 5.0 then 30 # days
		when 10.0 then 30 # days
	end
end

def clean_region(region)
	case region
		when 'Caribbeab' then 'Caribbean'
		else region
	end
end

def save_rows(header, rows, filename)
	puts "Saving #{rows.count} rows"
	CSV.open(filename, "w") do |csv|
		csv << header
		rows.each do |r|
			csv << r
		end
	end
end

def translate_telna_country_to_airalo(telna_country)

	case telna_country

		# there are two possible mappings for Congo
		# we should map to the cheaper one!
		when 'Congo' then 'Democratic Republic of the Congo'  # DRC is 22% cheaper than  RC
		#when 'Congo' then 'Republic of the Congo'			  # 28% more expensive than DRC

		# spelling difference
		when 'Hong Kong' then 'China (Hong Kong)'
		when 'Iran' then 'Iran (Islamic Republic of)'
		when 'Ivory Coast' then "Cote d'Ivoire"
		when 'Palestine' then 'Palestine State of'
		when 'Saint Maarten' then 'Saint Martin'
		when 'Turks and Caicos' then 'Turks and Caicos Islands'
		when 'UAE' then 'United Arab Emirates'
		when 'USA' then 'United States'

		# child-parent relationship
		when 'Saint Vincent' then 'Saint Vincent and the Grenadines'
		when 'Zanzibar' then 'Tanzania'

		# No Airalo products in the following countries; return a nil value

		# Europe
		when 'Andorra' then nil # tiny country between France and Spain
		when 'Lichtenstein' then nil # tiny country between Germany and Switzerland - included in Airalo Europe (Regional) SIM
		when 'San Marino' then nil # small country completely surrounded by Italy
		when 'Jersey' then nil # island in English channel
		when 'Monaco' then nil # on the coastline in France very close to Spain

		# Asia
		when 'Lebanon' then nil 
		when 'Bhutan' then nil # Himalayas
		when 'Myanmar' then nil # between Bangledesh and Thailand
		when 'Macao' then nil # beside Hong Kong
		when 'Seychelles' then nil # indian ocean
		
		when 'Vanuatu' then nil # south pacific ocean
		when "French Polynesia" then nil # pacific ocean

		# Africa
		when 'Angola' then nil 
		when 'Burkina Faso' then nil
		when 'Burundi' then nil # included in Airalo Africa (Regional) SIM
		when 'Mayotte' then nil # indian ocean; included in Airalo Africa (Regional) SIM
		when 'Namibia' then nil
		when 'Togo' then nil
		when 'Zimbabwe' then nil

		# Carribean and South America
		when 'Cuba' then nil
		when 'Venezuela' then nil

		else telna_country

	end

end