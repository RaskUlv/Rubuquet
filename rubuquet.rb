#!/usr/bin/env ruby
# coding: utf-8

require 'fileutils'

if ARGV.length == 0 or ARGV.length == 1 or ARGV.length > 2
  puts "Please, specify a file to OCR and language or read README file to get help."
  exit
else
  inFile = ARGV[0]
  argFileExt = File.extname(inFile)
  fileName = File.basename(inFile, ".*")
  fileLang = ARGV[1]
end

workDir = File.expand_path(File.dirname(__FILE__))
tempDir = "/tmp/rubuquet_tmp"

FileUtils.mkdir(tempDir) unless Dir.exists?(tempDir)

def pdfInfo( pdFile )
  return IO.popen(system("pdfinfo", inFile).to_s)
end

def ocr_file( docPages, fileLang, tempDir, workDir, fileName )
  print "Starting OCR process. Please wait"

  docPages.times {
  |page|
  fmtPage = format("%.4d", "#{page+1}")
  commnd = "cuneiform #{tempDir}/image-#{fmtPage}.png -l #{fileLang} -o #{tempDir}/text-#{fmtPage}.txt >> /dev/null 2>> /dev/null"
  system(commnd)
  if page/5.0 == (page/5).to_i
    print "."
  end
  }

  puts "\nOCR is done: #{fileName}"
  outFile = File.new("#{workDir}/#{fileName}.txt", "a+")

  Dir["#{tempDir}/*.txt"].each {
  |filetx|
  tempst = File.read(filetx)
  File.open("#{workDir}/#{fileName}.txt", "a+") { |file| file.write tempst }
  }

  FileUtils.rm_rf(tempDir)
end

def pages ( pdFile )
  expar = ["pdfinfo", "#{pdFile}"]
  f = IO.popen(expar).grep(/Pages:\s\d*/)
  fString = f[0]
  pagenums = (/\d*$/).match(fString)
  pdfPages = pagenums[0].to_i
  return pdfPages
end

### Work with PDF file format

if argFileExt == '.pdf'
  docPages = pages(inFile)
  puts "Converting to png: #{fileName}"
  system("gs", "-r150", "-q", "-sDEVICE=pngmono", "-dDOINTERPOLATE", "-dNOPAUSE", "-dTextAlphaBits=4", "-dGraphicsAlphaBits=4", "-sOutputFile=#{tempDir}/image-%04d.png", "--", "#{inFile}")
  ocr_file(docPages, fileLang, tempDir, workDir, fileName)

### Work with DJVU file format

elsif argFileExt == '.djvu'
  puts "Converting to png: #{fileName}"
  system("ddjvu", "-format=pdf", "-mode=black", "-quality=100", "#{inFile}", "#{tempDir}/#{fileName}.pdf")
  docPages = pages("#{tempDir}/#{fileName}.pdf")
  system("gs", "-r150", "-q", "-sDEVICE=pngmono", "-dDOINTERPOLATE", "-dNOPAUSE", "-dTextAlphaBits=4", "-dGraphicsAlphaBits=4", "-sOutputFile=#{tempDir}/image-%04d.png", "--", "#{tempDir}/#{fileName}.pdf")
  ocr_file(docPages, fileLang, tempDir, workDir, fileName)
else
  puts "File type #{argFileExt} not supported"
end

