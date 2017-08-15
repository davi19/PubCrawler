require 'nokogiri'
require 'open-uri'
require 'watir'
require 'webdrivers'


#Setando iniciando variaveis principais

Selenium::WebDriver::Chrome.driver_path='/home/davi/Downloads/chromedriver'
navegador = Watir::Browser.start 'https://www.ncbi.nlm.nih.gov/pubmed/?term=diabetes'
documento = Nokogiri::HTML(open("https://www.ncbi.nlm.nih.gov/pubmed/?term=diabetes"))



#Recupera total de pagina
paginas = documento.css(".page")

totalPaginas=0
paginas[0..-1].each do |row|
  quantidade= row.text.split('of')
  totalPaginas =quantidade[1]
  puts totalPaginas
  break
end


#paginacao = navegador.text_field id: 'pageno'
#paginacao.set totalPaginas.to_i
#navegador.send_keys :enter

#Inicio do loop central
    pagina=0
    while(pagina!=totalPaginas)
      pmid=documento.css(".rprtid/dd")
      pmid[0..-1].each do |row|
        documentoArtigo= Nokogiri::HTML(open("https://www.ncbi.nlm.nih.gov/pubmed/#{row.text}"))
        autores =documentoArtigo.css(".auths")
        filiacao =documentoArtigo.css(".afflist")
        resumo =documentoArtigo.css(".abstr")
        palavrasChave =documentoArtigo.css(".keywords")
        if(resumo.empty?|| autores.empty?)
          puts "Vazio"
        else
          artigo =" #{autores.text} \n #{filiacao.text} \n #{resumo.text} \n #{palavrasChave.text}"
          puts artigo
        end
      end
      link = navegador.link :text => 'Next >'
      link.click
      documento = Nokogiri::HTML.parse(navegador.html)
      pagina=pagina+1
    end
