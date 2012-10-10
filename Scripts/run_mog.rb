#!/usr/bin/ruby

MOGENERATOR_BIN = `which mogenerator`.chomp
PLIST_BUDDY_BIN = "/usr/libexec/PlistBuddy"

SCRIPT_PATH = File.expand_path(File.dirname(__FILE__)).gsub(" ","\\ ")
BASE_PATH = "#{SCRIPT_PATH}/../Albums"
MODELS_DIR = "#{BASE_PATH}/Models"
MODEL_DIR = "#{BASE_PATH}/Model.xcdatamodeld"
MODEL_CURRENT_VERSION_FILE = "#{MODEL_DIR}/.xccurrentversion"
MODEL_CURRENT_VERSION = `#{PLIST_BUDDY_BIN} -c "Print :_XCCurrentVersionName" #{MODEL_CURRENT_VERSION_FILE}`.chomp.gsub(" ","\\ ")
MODEL_PATH = "#{MODEL_DIR}/#{MODEL_CURRENT_VERSION}"
MACHINE_DIR = "#{MODELS_DIR}/Machine"
HUMAN_DIR = "#{MODELS_DIR}/Human"
CMD = "#{MOGENERATOR_BIN} --model #{MODEL_PATH} --machine-dir #{MACHINE_DIR} --human-dir #{HUMAN_DIR} --template-var arc=true --base-class=MVBaseModel"

puts `#{CMD}`