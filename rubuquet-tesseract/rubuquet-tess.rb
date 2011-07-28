#!/usr/bin/env ruby
# coding: utf-8

require 'fileutils'

if ARGV.length == 0 or ARGV.length == 1 or ARGV.length > 2
  puts "Please, specify a file to OCR and language or read README file to get help."
  exit
else
  in_file = ARGV[0]
  arg_file_ext = File.extname(in_file)
  file_name = File.basename(in_file, ".*")
  file_lang = ARGV[1]
  file_dir = File.dirname(in_file)
end

work_dir = File.expand_path(File.dirname(__FILE__))
temp_dir = "/tmp/rubuquettess_tmp"

FileUtils.mkdir(temp_dir) unless Dir.exists?(temp_dir)

def pdf_info( pdfile )
  return IO.popen(system("pdfinfo", in_file).to_s)
end

def ocr_file( doc_pages, file_lang, temp_dir, work_dir, file_name, file_dir )
  print "Starting OCR process. Pages left: #{doc_pages}"

  doc_pages.times {|page|
  fmt_page = format("%.4d", "#{page+1}")
  commnd = "tesseract  #{temp_dir}/image-#{fmt_page}.tif #{temp_dir}/text-#{fmt_page} -l #{file_lang} >> /dev/null 2>> /dev/null"
  system(commnd)
  i =doc_pages-page
  n = (doc_pages.to_s).length
  ifmt = format("%#{n}d", i)
  print "\b"*n+"#{ifmt}"
  }

  out_file = File.new("#{file_dir}/#{file_name}.txt", "a+")
  src_ents = Dir.entries( "#{temp_dir}" )
  src_fls = src_ents.grep(/.txt/).sort
  src_fls.each {|filetx|
  tempst = File.read("#{temp_dir}/#{filetx}")
  File.open("#{file_dir}/#{file_name}.txt", "a+") { |file| file.write tempst }
  }
  puts "\nOCR is done: #{file_name}"
  FileUtils.rm_rf(temp_dir)
end

def pages ( pdfile )
  expar = ["pdfinfo", "#{pdfile}"]
  f = IO.popen(expar).grep(/Pages:\s\d*/)
  f_string = f[0]
  pagenums = (/\d*$/).match(f_string)
  pdf_pages = pagenums[0].to_i
  return pdf_pages
end

### Work with PDF file format

if arg_file_ext == '.pdf'
  doc_pages = pages(in_file)
  puts "Preparing to OCR: #{file_name}"
  system("gs", "-r150", "-q", "-sDEVICE=tiffg4", "-dDOINTERPOLATE", "-dNOPAUSE", "-dTextAlphaBits=4", "-dGraphicsAlphaBits=4", "-sOutputFile=#{temp_dir}/image-%04d.tif", "--", "#{in_file}")
  ocr_file(doc_pages, file_lang, temp_dir, work_dir, file_name, file_dir)

### Work with DJVU file format

elsif arg_file_ext == '.djvu'
  puts "Preparing to OCR: #{file_name}"
  system("ddjvu", "-format=pdf", "-mode=black", "-quality=100", "#{in_file}", "#{temp_dir}/#{file_name}.pdf")
  doc_pages = pages("#{temp_dir}/#{file_name}.pdf")
  system("gs", "-r150", "-q", "-sDEVICE=tiffg4", "-dDOINTERPOLATE", "-dNOPAUSE", "-dTextAlphaBits=4", "-dGraphicsAlphaBits=4", "-sOutputFile=#{temp_dir}/image-%04d.tif", "--", "#{temp_dir}/#{file_name}.pdf")
  ocr_file(doc_pages, file_lang, temp_dir, work_dir, file_name, file_dir)
else
  puts "File type #{arg_file_ext} not supported"
end

