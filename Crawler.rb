require 'nokogiri'
require 'open-uri'
require 'watir'
require 'webdrivers'
require 'redis'

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
#navegador.close
#navegador = Watir::Browser.start 'https://www.ncbi.nlm.nih.gov/pubmed/?term=diabetes'
#paginacao = navegador.text_field id: 'pageno'
#paginacao.set 466
#navegador.send_keys :enter
#documento = Nokogiri::HTML.parse(navegador.html)
#Inicio do loop central
    pagina=1
    while(pagina!=totalPaginas)
      pmid=documento.css(".rprtid/dd")
      pmid[0..-1].each do |row|
        begin
          documentoArtigo= Nokogiri::HTML(open("https://www.ncbi.nlm.nih.gov/pubmed/#{row.text}"))
          autores =documentoArtigo.css(".auths")
          filiacao =documentoArtigo.css(".afflist")
          resumo =documentoArtigo.css(".abstr")
          palavrasChave =documentoArtigo.css(".keywords")
          if(resumo.empty?|| autores.empty?||filiacao.empty?)
            puts "Vazio"
          else
            artigo =" #{autores.text} | #{filiacao.text} |  #{resumo.text} | #{palavrasChave.text}"

            existe = redis.exists(row.text)

            if !existe
              redis.set(row.text,artigo)
              puts row.text
            else
              puts 'Artigo já cadastrado'
            end
        #Arvore de decisão
          filiacoes = filiacao.text.split(/[,;]/)
          filiacoes[0..-1].each do |fili|
            if fili.include? 'Author information1'
            fili = fili.tr('Author information1','')
            end
            if fili.include? 'Electronic address'
              semEmail = fili.split('.')
              existeinstituicao = redisinstituicao.exists(semEmail[0])
              if !existeinstituicao
                redisinstituicao.set(semEmail[0],row.text)
                puts semEmail[0]
              else
                puts "Instituição já cadastrada"
                anterior= redisinstituicao.get(fili)
                anterior= "#{anterior};#{row.text}"
                redisinstituicao.set(semEmail[0],anterior)
              end
            else
            existeinstituicao = redisinstituicao.exists(fili)
            if !existeinstituicao
              redisinstituicao.set(fili,row.text)
              puts fili
            else
              anterior= redisinstituicao.get(fili)
              anterior= "#{anterior};#{row.text}"
              redisinstituicao.set(fili,anterior)
              puts "Instituição já cadastrada"
            end
          end
          end
        end
      #Tratando negação do servidor
        rescue
          puts "TimeOUT"
        #Voltando a pagina correta
          puts "SALVO"
          navegador.close
          navegador = Watir::Browser.start 'https://www.ncbi.nlm.nih.gov/pubmed/?term=diabetes'
          paginacao = navegador.text_field id: 'pageno'
          paginacao.set pagina.to_i
          navegador.send_keys :enter
          documento = Nokogiri::HTML.parse(navegador.html)
       end
      end
        link = navegador.link :text => 'Next >'
        link.click
        documento = Nokogiri::HTML.parse(navegador.html)
        pagina=pagina+1
    end
