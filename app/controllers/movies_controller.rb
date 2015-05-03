class MoviesController < ApplicationController
	include MoviesHelper
  skip_before_filter :verify_authenticity_token
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  # For all responses in this controller, return the CORS access control headers.
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.

  def cors_preflight_check
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
    headers['Access-Control-Max-Age'] = '1728000'
  end

  def list   
	# start off empty array
	arrURL = []

	# define URLs
	arrURL.push('http://www.zmovie.tw/movies/new')
	arrURL.push('http://www.zmovie.tw/movies/featured')
	arrURL.push('http://www.zmovie.tw/movies/recent')
	arrURL.push('http://www.zmovie.tw/movies/recent_update')
	arrURL.push('http://www.zmovie.tw/movies/top')

	# get the request
	request = arrURL[params[:request].to_i]
	search = params[:search].to_s.downcase

	# scrape url	
	doc = returnWebDocument(request)

	# start with empty array
	arrMovies = [] 

	doc.search('a').each do |row|
		if (row['href'].to_s.downcase.include? "http://www.zmovie.tw/movies/view")
			# find relevant links
			objects = arrMovies.select { |obj| obj.href == row['href'] } 
			if objects.size == 0 && !(row['href'].include? 'comments')
				img_src = "http://www.zmovie.tw/files/movies/" + row['href'].to_s.split('/')[5] + ".jpg"
				objMovie = Movie.new(row['title'],row['href'],img_src)
				arrMovies.push(objMovie)
			end 
		end	
	end	

	# set instance variable for view
	@arrMovies = arrMovies

	# filter movies
	@arrMovies = @arrMovies.select { |item| item.title.downcase.include? search }

	# return json
	render json: JSON.pretty_generate(@arrMovies)

end

# authentication
def auth
	username = params[:username]
	password = params[:password]

	auth = [(username == ENV['username'] && password == ENV['password'] ? true : false)]

	# return json
	render json: JSON.pretty_generate(auth)
end

def openMovie
	# qualification system
	@movie = params[:url]

	arrMovies = [] 

	# fetch document
	doc = returnWebDocument(params[:url])

	@title = doc.css('title').text  

		doc.search('table').each do |row|

			if (row.to_s.start_with? '<table cellspacing="0" cellpadding="0" width="175">')
				row.search('a').each do |item| 
					if (!item['href'].include? 'zmovie') && (!item['href'].include? 'javascript') 
						# bottom block goes here...
						mtch = row.to_s.match(/([0-9]+% said good)/)
	 					if !mtch.nil?
	 						# this link is good....
	 						value_nb = mtch[0].match(/([0-9]+)/)
	 						if value_nb[0].to_i >= 50
								# qualifies...
								objMovieRating = MovieRating.new(item['href'],value_nb[0].to_i)
								arrMovies.push(objMovieRating)
							end
	 					end
					end
				end
			end
		end	
		# set instance variable for view
		@arrMovies = arrMovies.sort_by {|obj| obj.rating}.reverse

		render json: JSON.pretty_generate(@arrMovies)
	end

# define movie class
class Movie
   attr_accessor :title, :href, :img_src
   def initialize(title, href, img_src)
      @title = title
      @href = href
      @img_src = img_src
      @links = nil
      @status = nil
   end
end

# define movie rating class
class MovieRating
   attr_accessor :href, :rating
   def initialize(href, rating)
      @href = href
      @rating = rating
   end
end
end
