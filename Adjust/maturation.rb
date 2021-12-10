require_relative 'utility'

LAST_COHORT = 45
WEEKLY_W0_INDEX = 8

# load file
file = open('adjust_11_10_monthly.csv')
data = CSV.open(file).to_a
data = strip_header(data)

=begin
	[0, nil]
	[1, "date"]
	[2, "partner"]
	[3, "cost"]
	[4, "installs"]
	[5, "date-partner"]
	[6, "period"]
	[7, "revenue_total"]
	[8, "revenue_events_total"]
	[9, "paying_users"]
	[10, "cohort_size"]
=end

output = Array.new

date_start = Date.parse("Jan.  1, 2018")
date_end   = Date.today - 33

# load weekly data to lookup the W0 value for the start date
file = open('weekly.csv')
weekly_data = CSV.open(file).to_a
weekly_data = strip_header(weekly_data)

=begin
	[0, "Start Date"]
	[1, "End Date"]
	[2, "Window (days)"]
	[3, "Partner"]
	[4, "Revenue"]
	[5, "Cost"]
	[6, "Days without cost"]
	[7, "Days without samples"]
	[8, "W0 ROAS"]
	[9, "M15 ROAS"]
	[10, "M15 ROAS Sample Size"]
	[11, "STDEV"]
=end

w = 7

# load weekly data in order to insert W0 value into LTV calculation (so that we can use it as a lookup table later)
weekly_data = weekly_data.select { |d| d[2].to_i.eql?(w) }  # only one type of window is selected
weekly_data = weekly_data.select { |d| d[6].to_i.zero?   }  # all days have costs
weekly_data = weekly_data.select { |d| ! d[8].nil? } # roas is not nil (index 8)

if ! weekly_data.any?
	puts "\nWarning: Weekly data not found".red
	puts "Warning: Weekly data not found".red
	sleep 1
end

# generate values

["Adwords", "Apple"].each do |partner|
#["Adwords"].each do |partner|

	rows_partner = data.select { |d| d[2].eql?(partner.downcase) }
	weekly_rows_partner = weekly_data.select { |d| d[3] == partner }

	(date_start..date_end).each do |date|

		#rows_date = data.select { |d| Date.parse(d[1]).eql >= date and Date.parse(d[1]) <= date + (w - 1) }
		rows_date = rows_partner.select { |d| Date.parse(d[1]).eql?(date)  }
		
		puts date.to_s.yellow
		roass = Array.new
		months_old = age(date)
		last_increase = nil

		# for each cohort
		(0..LAST_COHORT).each do |cohort|

			#puts cohort.to_s.green
			is_mature = months_old > cohort

			# select data for cohort
			rows_cohort = rows_date.select { |d| d[6].eql?(cohort.to_s) }

			# calculate roas
			cost = rows_cohort.map { |d| d[3].to_f }.inject(0, :+) # doesn't change
			rev  = rows_cohort.map { |d| d[7].to_f }.inject(0, :+)
			roas = nil
			if cost.zero?
				puts "#{date} cohort #{cohort} #{partner} - cannot divide by zero".red
			elsif ! is_mature
				# leave nil
			else
				roas = rev / cost
				roas = roas.round(5)

				# keep track of last increase
				if roass.any? and roas > roass.last
					last_increase = cohort
				end

			end

			roass << roas

		end

		# look up W0 for this date
		w0 = nil
		weekly_rows_date = weekly_rows_partner.select { |d| Date.parse(d.first) == date }
		if weekly_rows_date.any?
			w0 = weekly_rows_date.first[WEEKLY_W0_INDEX]
		else
			puts "W0 missing for #{date} and #{partner}".yellow
		end

		# add to output
		output << [date.to_s, partner, months_old, last_increase, w0, roass].flatten

	end

end

# generate header
header = ['Date', 'Partner', 'Age', 'Last Increase', 'W0']
(0..LAST_COHORT).each do |c|
	header << "M" + c.to_s
end

# save results
save_rows(header, output, "maturation.csv")