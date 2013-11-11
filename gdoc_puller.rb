#!/usr/bin/env ruby

require "rubygems"
require 'bundler/setup'
require "google_drive"
require "highline/import"

class CsvPuller
  def initialize( user, pass )
    @session = GoogleDrive.login( user, pass )
  end

  def pull( title )
    puts "Looking up #{title}"
    spreadsheet = @session.spreadsheet_by_title title

    if spreadsheet.nil?
      puts "Unable to load #{title}"
    else
      worksheets = @session.request :get, spreadsheet.worksheets_feed_url

      worksheets.search( "entry title" ).each_with_index do |entry_title, index|
        sheet_title = entry_title.text

        outfile = File.expand_path "~/Downloads/#{title}"
        FileUtils.mkdir_p outfile
        outfile = "#{outfile}/#{sheet_title.gsub( /\//, "_" )}.csv"

        puts outfile
        begin
          spreadsheet.export_as_file( outfile, "csv", index )
        rescue Exception => e  
          puts "problem"
          puts e
        end
      end
    end
  end

  def spreadsheets
    @session.spreadsheets.collect { |x| x.title }
  end
end

class PullerConfig
  def initialize( savepass = false)
    load
    @savepass = savepass
  end

  def config_file
    ".gdoc_info.yml"
  end

  def load
    # puts "Loading"
    if File.exists? config_file
      response  = YAML.load( File.read( config_file ) ) 
      @username = response[:user]
      @password = response[:pass]
      @docs     = response[:docs]
    end
  end

  def save
    # puts "Saving"
    options = { user: @username.to_s, docs: (@docs || []) }
    options[:pass] = @password.to_s if @savepass

    File.open( config_file, "w" ) do |o|
      o.puts YAML.dump( options || {} )
    end
  end

  def user
    @username ||= ask( "Username : " ) { |q| q.echo = true }
    save
    @username
  end

  def pass
    @password ||= ask( "Password for #{@username}: " ) { |q| q.echo = '.' }
    save
    @password
  end

  def docs
    @docs ||= []
    adddoc if @docs == [] 
    save
    @docs
  end

  def adddoc puller
    puts "Adding a document"

    doc = choose do |menu|
      menu.header = "Select a document to add ot the list"
      menu.prompt = "Please choose a document"

      menu.choices *puller.spreadsheets
    end

    @docs ||= []
    @docs << doc
    puts "#{doc} added, run with pulldocs now"
    save
  end
end

config = PullerConfig.new ARGV.delete( "--savepass" )

run = false

if ARGV.delete "adddoc"
  run = true
  puller = CsvPuller.new( config.user, config.pass )
  config.adddoc puller
end

if ARGV.delete "pulldocs"
  run = true
  puller = CsvPuller.new( config.user, config.pass )

  config.docs.each do |doc|
    puller.pull doc
  end
end

if !run
  puts "Usage: gdoc_puller.rb [adddoc] [pulldocs] [--savepass]"
  puts
  puts "  addoc will add a document to the list to pull"
  puts "  pulldocs will pull down the documents"
  puts "  --savepass will save your plain text password"
end
