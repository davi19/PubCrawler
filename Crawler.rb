require 'nokogiri'
require 'open-uri'
require 'watir'
require 'webdrivers'
require 'redis'
require 'fuzzystringmatch'

jarow = FuzzyStringMatch::JaroWinkler.create( :native )
redis = Redis.new
redisinstituicao = Redis.new
#Setando iniciando variaveis principais
begin
Selenium::WebDriver::Chrome.driver_path='/home/davi/Downloads/chromedriver'
navegador = Watir::Browser.start 'https://www.ncbi.nlm.nih.gov/pubmed/?term=diabetes'
documento = Nokogiri::HTML(open("https://www.ncbi.nlm.nih.gov/pubmed/?term=diabetes"))
redis.select(1)
redisinstituicao.select(2)
#Recupera total de pagina
paginas = documento.css(".page")
totalPaginas=0
paginas[0..-1].each do |row|
  quantidade= row.text.split('of')
  totalPaginas =quantidade[1]
  puts totalPaginas
  break
end
#Tratando falta de internet
rescue SocketError
  puts "Sem Conexão"
end
paginacao = navegador.text_field id: 'pageno'
paginacao.set 4591
navegador.send_keys :enter
documento = Nokogiri::HTML.parse(navegador.html)
#Inicio do loop central
    pagina=4591
    while(pagina!=totalPaginas)
      pmid=documento.css(".rprtid/dd")
      pmid[0..-1].each do |row|
        begin
          documentoArtigo= Nokogiri::HTML(open("https://www.ncbi.nlm.nih.gov/pubmed/#{row.text}"))
          autores =documentoArtigo.css(".auths")
          filiacao =documentoArtigo.css(".ui-ncbi-toggler-slave/dd")
          resumo =documentoArtigo.css(".abstr")
          palavrasChave =documentoArtigo.css(".keywords")
          controle=false

          if(resumo.empty?|| autores.empty?||filiacao.empty?)
            puts "Vazio"
          else
            artigo =" #{autores.text} | #{filiacao.text} |  #{resumo.text} | #{palavrasChave.text}"

              existe = redis.exists(row.text)
            if existe
                p "Já cadastrado"
            else
                puts row.text
              redis.setnx(row.text,artigo)
              todas = redisinstituicao.keys('*')
              filiacao[0..-1].each do |row2|
                fili= row2.text.split(",")
                for count in fili
                  for instituicao2 in todas
                    if jarow.getDistance( count,instituicao2 ) > 0.9
                      artigosinsti = redisinstituicao.get(instituicao2)
                      novoValor= "#{artigosinsti} ; #{row.text}"
                      redisinstituicao.set(instituicao2,novoValor)
                      controle=true
                    end
                  end
                  if !controle
                    redisinstituicao.set(count,row.text)
                  end
                end
              end
            end
        end
      #Tratando negação do servidor
        rescue
          puts "TimeOUT"
        #Voltando a pagina correta
          puts "SALVO"
          out = File.new("output.txt", "w")
          out.puts "#{pagina}"
          begin
            navegador.close
            navegador = Watir::Browser.start 'https://www.ncbi.nlm.nih.gov/pubmed/?term=diabetes'
            paginacao = navegador.text_field id: 'pageno'
            paginacao.set pagina.to_i
            navegador.send_keys :enter
            documento = Nokogiri::HTML.parse(navegador.html)
          # Recuperando erro do erro
          rescue
            navegador.close
            navegador = Watir::Browser.start 'https://www.ncbi.nlm.nih.gov/pubmed/?term=diabetes'
            paginacao = navegador.text_field id: 'pageno'
            paginacao.set pagina.to_i
            navegador.send_keys :enter
            documento = Nokogiri::HTML.parse(navegador.html)
        end
       end
      end
        link = navegador.link :text => 'Next >'
        link.click
        documento = Nokogiri::HTML.parse(navegador.html)
        pagina=pagina+1
    end
