##
# Simpe link shotter. Just as exampe of REST service:
#    GET / - return inormation
#    GET /:code redirect to link
#    POST / {:url=> ?} - store URL and return code
#
# Usage:
#  gem install sinatra
#  ruby sinatra.rb
#
# Test:
#    curl -F "url=http://dl.sumdu.edu.ua" 127.0.0.1:4567
#    curl 127.0.0.1:4567/B
# 
# Author:
#    Kuzikov Borys
#    CC-BY 3.0
#

require 'rubygems'
require 'sinatra'

  configure do
    File.open('storage.db','a+'){}
  end

  get '/?:code?' do
    unless params[:code].nil? || params[:code].empty?
      line = code2dec params[:code]
      url =  read_by_line_number(line) rescue halt(404)
      url = 'http://'+url unless url.start_with?('http')
      return redirect url, 303
    end
    erb :index
  end

  post '/' do
    url = params[:url]
    raise 'URL is too long' if url.size > 64*1024
    code = dec2code(append(url))
    url = BASE_URL+code
    erb :index, :locals => {:url=>url}
  end

  not_found do
    erb :index, :locals => {:error=>"URL not found :(",:code=>404}
  end

  error Object do
    [500, erb(:index, :locals => {:error=>env['sinatra.error'].name, :code=>500})]
  end

private

  SYMBOLS = ('A'..'Z').to_a+('a'..'z').to_a+('0'..'9').to_a - %w(0 O I l)
  SYMBOLS_LENGTH = SYMBOLS.size
  BASE_URL = 'http://localhost:4567/'

  ##
  #  Decode decimal from base58
  #
  def code2dec code
    raise 'Code too long' if code.size > 10
    raise 'Code too short' if code.size == 0
    dec = 0
    code.reverse.chars.each do  |symbol|
      int_position = SYMBOLS.index(symbol)
      raise "Bad char: #{symbol}" unless int_position
      dec = dec*SYMBOLS_LENGTH+int_position
    end
    dec
  end

  ##
  #  Encode decimal to base58.
  #
  def dec2code dec
    out = ''
    while (dec>0)
      out << SYMBOLS[dec % SYMBOLS_LENGTH]
      dec = dec / SYMBOLS_LENGTH
    end
    out
  end

  ##
  #  Read Uri from file by line number.
  #
  def read_by_line_number line_number
    uri = ''
    File.open('storage.db','r') do |f|
      count = f.gets.to_i
      raise 'URI unaccesible' if count < line_number
      while line_number >0
        uri = f.gets
        line_number -= 1
      end
    end
    uri
  end

  ##
  #  **Append** Uri to file, retrn count of uri in file.
  #
  def append uri
    count = 0
    File.open('storage.db','r+') do |f|
      f.flock(File::LOCK_EX)
      count = f.gets.to_i+1
      f.seek(0,IO::SEEK_SET)
      f.write "%20i" % count
      f.seek(0,IO::SEEK_END)
      f.write "\n"+uri
      f.flock(File::LOCK_UN)
    end
    count
  end
  
__END__

@@ layout
<html>
  <head>
    <title>Super Simple URL Cutter</title>
    <meta charset="utf-8" />
      <style>
body {
  background: #F2F1F0;
  font-family: "Lucida Grande","Lucida Sans Unicode","Lucida Sans",Geneva,Verdana,sans-serif;}
span{
   background:#4B8DF8;
   color:#FFF;
   padding:2px 10px;}
h1 *{font-size:48px;}
h2 *{font-size:14px;}
.center {
  margin: 4em auto;
  overflow: visible;
  width: 500px;}
input {height: 42px; }
input[type=text] {
  width: 360px;
  border: 1px dashed #AAA;}
input[type=submit]{
  width: 42px;
  background: url("http://cdn1.iconfinder.com/data/icons/cc_mono_icon_set/blacks/32x32/clipboard_cut.png") no-repeat #F1F1F1;
  border: #DDD 1px solid;}
.error{
  background:red;
  span.error
}
.code{
  background: none;
  color: black;
  font-size: 72px;
  font-weight: bold;
  left: 72px;
  position: absolute;
  top: 72px;}
.result {display:block;}
    </style>
  </head>
  <body>
    <div class="center">
      <h1><span>Сокращатель</span></h1>
      <h2><span>Еще один укорачиватель ссылок</span></h2>
      <%= yield %>
    </div>
  </body>
</html>

@@ index
  <% url ||= ''; error||= ''; %>
  <% unless url.empty? %>
    <span class="result">Сокращенная ссылка: <b><a href="<%= url %>"><%= url %></a></b></span>
    <span class="result">Сократить еще?</span>
  <% end %>
  <% unless error.empty? %>
    <span class="error">Error:<%= error %></span>
    <span class="code"><%=code %></span>
  <% end %>
  <form method="POST" action='http://127.0.0.1:4567'>
    <input type="text" name="url"/>
    <input type="submit" value="" /></input>
  </form>