# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'thinking_sphinx/test'

# Use this block to run a set of examples inside sphinx.
# Call #index_sphinx once your test data is set up.
def sphinx_environment(*tables, &block)
  transactional = use_transactional_fixtures
  begin
    init_sphinx_before_all(tables)
    run_sphinx_around_example
    yield
  ensure
    reset_configuration_affter_all(transactional)
  end
end

def index_sphinx
  ThinkingSphinx::Test.index
  # Wait for index to finish. If entries are not found, probably increase the sleep period.
  sleep 1
  sleep 0.25 until index_finished?
end

def init_sphinx_before_all(tables)
  obj = self
  before(:all) do
    obj.use_transactional_fixtures = false
    DatabaseCleaner.strategy = :truncation, { only: tables }
    ThinkingSphinx::Test.init
  end
end

def run_sphinx_around_example
  around(:each) do |example|
    ThinkingSphinx::Test.run do
      if ThinkingSphinx::Configuration.instance.controller.running?
        DatabaseCleaner.start
        example.call
        DatabaseCleaner.clean
      else
        puts 'SPHINX NOT RUNNING!'
      end
    end
  end
end

def reset_configuration_affter_all(transactional)
  obj = self
  after(:all) do
    DatabaseCleaner.strategy = defined?(DB_CLEANER_STRATEGY) ? DB_CLEANER_STRATEGY : :transaction
    obj.use_transactional_fixtures = transactional
  end
end


def index_finished?
  Dir[Rails.root.join('db', 'sphinx', 'test', '*.{new,tmp}.*')].empty?
end
