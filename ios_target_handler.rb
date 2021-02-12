#!/usr/bin/env ruby

require 'rubygems'
require 'xcodeproj'
require 'nokogiri'

if ARGV.length < 5
    puts "Please provide input in the following order: store name, store id, website id, base url, company name"
    exit
end

puts "Initializing..."
name = ARGV[0]
store_id = ARGV[1]
website_id = ARGV[2]
base_url = ARGV[3]
company_name = ARGV[4]
nameWithoutSpaces = name.gsub(/\s+/, "")
dir_root = 'ClientStore/'
launch_screen_file_name = 'LaunchScreen' + nameWithoutSpaces
lanuch_screen_target = dir_root + 'Mobikul/StoryBoards/Base.lproj/' + launch_screen_file_name + '.storyboard'
lanuch_screen_source = dir_root + 'Mobikul/StoryBoards/Base.lproj/LaunchScreen.storyboard'
dir_assets = dir_root + 'Mobikul/Assets.xcassets/'
filename_app_icon = 'AppIcon' + nameWithoutSpaces
filename_artboard = 'Artboard' + nameWithoutSpaces
dir_app_icon_src = dir_assets + 'AppIconFashion.appiconset'
dir_app_icon_target = dir_assets + filename_app_icon + '.appiconset'
dir_artboard_src = dir_assets + 'Artboard.imageset'
dir_artboard_target = dir_assets + filename_artboard + '.imageset'


info_plist_en_src = dir_root + 'Base.lproj/Info.plist'
info_plist_ar_src = dir_root + 'ar.lproj/Info.plist'

info_plist_en_target = dir_root + 'Base.lproj/' + nameWithoutSpaces + '-Info.plist'
info_plist_ar_target = dir_root + 'ar.lproj/' + nameWithoutSpaces + '-Info.plist'

puts "Opening Xcode project..."
proj = Xcodeproj::Project.open('ClientStore.xcodeproj')
src_target = proj.targets.find { |item| item.to_s == 'ClientStoreDemoFashion' }

# create target
puts "Creating new target " + nameWithoutSpaces + "..."
target = proj.new_target(src_target.symbol_type, nameWithoutSpaces, src_target.platform_name, src_target.deployment_target)
target.product_name = name

# create scheme
puts "Creating new scheme " + nameWithoutSpaces + "..."
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(proj.path, nameWithoutSpaces)

# update build settings
puts "Copying build settings..."
target.build_configurations.map do |item|
  item.build_settings.update(src_target.build_settings(item.name))
end

# copy build_phases
puts "Copying build phases..."
phases = src_target.build_phases.reject { |x| x.instance_of? Xcodeproj::Project::Object::PBXShellScriptBuildPhase }.collect(&:class)

phases.each do |klass|
  src = src_target.build_phases.find { |x| x.instance_of? klass }
  dst = target.build_phases.find { |x| x.instance_of? klass }
  unless dst
    dst ||= proj.new(klass)
    target.build_phases << dst
  end
  dst.files.map { |x| x.remove_from_project }

  src.files.each do |f|
    file_ref = proj.new(Xcodeproj::Project::Object::PBXFileReference)
#    f.file_ref.instance_variable_defined?("@isa") && file_ref.isa = f.file_ref.isa
    f.file_ref.instance_variable_defined?("@name") && file_ref.name = f.file_ref.name
    f.file_ref.instance_variable_defined?("@path") && file_ref.path = f.file_ref.path
    f.file_ref.instance_variable_defined?("@source_tree") && file_ref.source_tree = f.file_ref.source_tree
    f.file_ref.instance_variable_defined?("@last_known_file_type") && file_ref.last_known_file_type = f.file_ref.last_known_file_type
    f.file_ref.instance_variable_defined?("@fileEncoding") && file_ref.fileEncoding = f.file_ref.fileEncoding
    f.file_ref.instance_variable_defined?("@include_in_index") && file_ref.include_in_index = f.file_ref.include_in_index
    
    begin
      file_ref.move(f.file_ref.parent)
    rescue
    end

    build_file = proj.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.file_ref = f.file_ref
    dst.files << build_file
  end
end

# copy info-plist files
puts "Creating info-plist files..."
FileUtils.cp(info_plist_en_src, info_plist_en_target)
FileUtils.cp(info_plist_ar_src, info_plist_ar_target)


# copy launch screen
puts "Creating launch screen..."
FileUtils.cp(lanuch_screen_source, lanuch_screen_target)
group_launch_screen = proj.main_group.find_subpath(dir_root + 'Mobikul/StoryBoards')
reference_launch_screen = group_launch_screen.new_reference('Base.lproj/'+ launch_screen_file_name + '.storyboard')

resources = target.build_phases.find { |x| x.instance_of? Xcodeproj::Project::Object::PBXResourcesBuildPhase }
resources.add_file_reference(reference_launch_screen)

puts "Creating app icon files..."
FileUtils.copy_entry(dir_app_icon_src, dir_app_icon_target)
puts "Creating artboard files..."
FileUtils.copy_entry(dir_artboard_src, dir_artboard_target)

puts "Update launch screen image..."
@doc = Nokogiri::XML(File.open(lanuch_screen_target))
resourceImage = @doc.xpath("//image").first
resourceImage["name"] = filename_artboard
imageView = @doc.xpath("//imageView").first
imageView["image"] = filename_artboard
File.write(lanuch_screen_target, @doc.to_xml)


puts "Updating build configurations..."
target.build_configurations.each do |config|
    config.build_settings['INFOPLIST_FILE'] = info_plist_en_target
    config.build_settings['PRODUCT_NAME'] = name
    config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = filename_app_icon
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.storespal.' + nameWithoutSpaces
end

puts "Creating plist group..."
plist_group = proj.main_group.new_variant_group(nameWithoutSpaces + '-Info.plist')
plist_group.new_reference(info_plist_en_target)
plist_group.new_reference(info_plist_ar_target)

puts "Updting target properties in plist..."
plist = Xcodeproj::Plist
plist_values = plist.read_from_path(info_plist_en_target)

plist_values.store("StoreId", store_id)
plist_values.store("CFBundleShortVersionString", "1.0")
plist_values.store("CFBundleVersion", "1")
plist_values.store("UILaunchStoryboardName", launch_screen_file_name)
plist_values.store("appNameSmall", name.downcase)
plist_values.store("BaseUrl", base_url)
plist_values.store("companyName", company_name)
plist_values.store("FacebookDisplayName", name)
plist_values.store("CFBundleDisplayName", name)
plist_values.store("WebsiteId", website_id)
plist_values.store("logoImage", filename_artboard)

plist.write_to_path(plist_values, info_plist_en_target)

puts "Creating new directory for GoogleService-Info.plist file..."
group_environments = proj.main_group.find_subpath('Environments')
FileUtils.mkdir_p 'Environments/' + nameWithoutSpaces
group_environments.new_group(nameWithoutSpaces)

puts "Updating Podfile..."
if File.open('Podfile').each_line.any?{|each_line| each_line.include?(nameWithoutSpaces)}
  puts "Target " + nameWithoutSpaces + " already exists..."
else
  open('Podfile', 'a') do |f|
   f.puts "target \'" + nameWithoutSpaces + "\' do"
   f.puts "    shared_pods"
   f.puts "end"
   end
end

# add files
#classes = proj.main_group.groups.find { |x| x.to_s == 'Group' }.groups.find { |x| x.name == 'Classes' }
#sources = target.build_phases.find { |x| x.instance_of? Xcodeproj::Project::Object::PBXSourcesBuildPhase }
#file_ref = classes.new_file('test.m')
#build_file = proj.new(Xcodeproj::Project::Object::PBXBuildFile)
#build_file.file_ref = file_ref
#sources.files << build_file

puts "Saving project..."
proj.save

puts "Congrattulations...."

# set new info.plist files to this target
