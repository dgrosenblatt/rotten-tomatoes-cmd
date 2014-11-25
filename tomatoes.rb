require 'json'
require 'net/http'
require 'open-uri'
require 'pry'

api_key = ENV['RT_API_KEY']
critic_profiles = {}
query = ""
loop do
  puts "Enter a movie or type see scores to finish:"
  query = gets.chomp.downcase
  break if query == "see scores"
  movie = JSON.parse(Net::HTTP.get(URI("http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=#{api_key}&q=#{URI::encode(query)}")), symbolize_names:true)[:movies][0]
  binding.pry

  if movie
    reviews = JSON.parse(Net::HTTP.get(URI("http://api.rottentomatoes.com/api/public/v1.0/movies/#{movie[:id]}/reviews.json?review_type=top_critic&page_limit=50&page=1&apikey=#{api_key}")), symbolize_names:true)[:reviews]
    puts "Was \"#{movie[:title]}\" rotten or fresh?"
    freshness = gets.chomp.downcase
    reviews.each do |review|
      if !critic_profiles.has_key?("#{review[:critic]}, #{review[:publication]}")
        critic_profiles["#{review[:critic]}, #{review[:publication]}"] = { agree: 0, disagree: 0}
      end

      if review[:freshness] == freshness
        critic_profiles["#{review[:critic]}, #{review[:publication]}"][:agree] += 1
      else
        critic_profiles["#{review[:critic]}, #{review[:publication]}"][:disagree] += 1
      end
    end
  else
    puts "Nothing found on Rotten Tomatoes. Try again."
  end
end

# maybe sort by total agree; too many 1/1 at top of results
sorted_critics = critic_profiles.sort_by do |name, sim|
  [-(sim[:agree]/(sim[:agree]+sim[:disagree])), -(sim[:agree]+sim[:disagree])]
end
puts "You have similar taste in movies to:"
sorted_critics.each do |critic|
  total = (critic[1][:agree]+critic[1][:disagree])
  pct = (((critic[1][:agree].to_f)/total)*100).round(2)
  puts "#{critic[0]} - #{pct} % (#{critic[1][:agree]} of #{total})" if  pct > 50
end
