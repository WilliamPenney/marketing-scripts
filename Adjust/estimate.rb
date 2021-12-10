MATURATION_WO_INDEX = 4

def estimate_maturation(roas, partner)
	lookup = load_maturation_lookup(partner)
	roas_min = roas * (1 - SPREAD / 2)
	roas_max = roas * (1 + SPREAD / 2)
	samples = lookup.select { |r| r.first >= roas_min and r.first <= roas_max }
	count = samples.count
	if count.zero?
		# cannot estimate
		[nil, nil, nil]
	else
		final_roas = samples.map { |r| r.last }.inject(0, :+) / count
		stdev_samples = samples.map { |r| r.last }
		[final_roas.round(3), count, stdev(stdev_samples).round(3)]
	end
end

def load_maturation_lookup(partner = 'Adwords')
	file = open('maturation.csv')
	m = CSV.open(file).to_a
	m = strip_header(m)
	m = m.select { |r| r[1].eql?(partner) } # correct partner
	m = m.select { |r| ! r[MATURATION_WO_INDEX].nil? } 		# W0 not nil
	m = m.select { |r| ! r[MATURATION_WO_INDEX + 1].nil? } 	# M0 not nil; at least one month of data
	m = m.select { |r| age(Date.parse(r.first)) > 15 }		# select mature
	m = m.map { |r| [ r[MATURATION_WO_INDEX].to_f, (r - [nil]).last.to_f] }
	m
end