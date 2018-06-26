require 'redis'
require 'axlsx'



redis = Redis.new
redis.select(2)


keys = redis.keys('*')
Axlsx::Package.new do |p|
    p.workbook.add_worksheet(:name => "Pie Chart") do |sheet|
        sheet.add_row ["instituição", "Total"]
for instituicao in keys
    puts redis.get(instituicao.to_s)
   
              

            sheet.add_row [instituicao, redis.get(instituicao.to_s).to_s.split(';').count]
        
    end
end
p.serialize('simple.xlsx')
    end