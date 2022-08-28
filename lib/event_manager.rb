require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename =  "output/thanks#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone_number)
  begin
    phone_number = phone_number.gsub(/\D/, "")
    phone_number_length = phone_number.length
    if phone_number_length < 10
      "Invalid Number"
    elsif phone_number_length == 10
      "(#{phone_number[0..2]})-#{phone_number[3..5]}-#{phone_number[6..9]}"
    elsif phone_number_length == 11 && phone_number[0] == "1"
      phone_number = phone_number.delete_prefix('1')
      "(#{phone_number[0..2]})-#{phone_number[3..5]}-#{phone_number[6..9]}"
    elsif phone_number_length == 11 && phone_number[0] != '1'
      "Invalid Number"
    else
      "Invalid Number"
    end
  rescue
    "Invalid Number"
  end
end

def time_targeting (date_time_stamp)
  date_time = DateTime.strptime(date_time_stamp, '%m/%d/%y %k:%M')
  date_time.hour
end

def day_targeting (date_time_stamp)
  date = Date.strptime(date_time_stamp, '%m/%d/%y')
  date.strftime("%A")

end


puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

peak_days = Hash.new(0)
peak_time = Hash.new(0)
contents.each do |row|
  id = row[0]
  name = row[:first_name]

  
  phone_number = clean_phone_numbers(row[:homephone])
  puts "Hello, #{name} you are signed up for phone notifications at #{phone_number}"

  day = day_targeting(row[:regdate])
  peak_days[day] += 1

  hour = time_targeting(row[:regdate])
  peak_time[hour] += 1

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts peak_time
puts peak_days
