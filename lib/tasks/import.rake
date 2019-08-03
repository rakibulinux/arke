namespace :db do
  desc 'import user configuration'
  task :import, [:file] => [:environment] do |task, args|

    fpath = args[:file]

    if File.exist?(fpath)
      puts "Importing #{fpath}"
      config = YAML.load(File.read(fpath))
      config.each do |model, data|
        case model
        when 'users'
          data.each {|u| User.create!(u) }
        when 'accounts'
          data.each {|a| Account.create!(a) }
        when 'robots'
          data.each {|r|
            accounts = r['accounts']
            r.delete('accounts')
            robot = Robot.new(r)
            accounts.each {|ac|
              robot.accounts << Account.find_by_id(ac['account_id'])
            }
            robot.save!
          }
        end
      end

    else
      fail "Invalid file: #{fpath}"
    end
  end
end
