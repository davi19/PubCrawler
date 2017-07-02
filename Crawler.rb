require 'nokogiri'
require 'open-uri'
require 'net_http_ssl_fix'

documento = Nokogiri::HTML(open('https://www.ncbi.nlm.nih.gov/pubmed/?term=diabetes'))

pagina=0
while(pagina!=20)
  pmid=documento.css(".rprtid/dd")
  pmid[0..-1].each do |row|
    paginaArtigo=open("https://www.ncbi.nlm.nih.gov/pubmed/#{row.text}")
    documentoArtigo= Nokogiri::HTMl(paginaArtigo)
    autores =documentoArtigo.css(".auths")
    filiacao =documentoArtigo.css(".afflist")
    resumo =documentoArtigo.css(".abstr")
    palavrasChave =documentoArtigo.css(".keywords")
    if(resumo.empty?|| autores.empty?)
      puts "Vazio"
    else
      artigo = autores.text+"\n"+filiacao+"\n"+resumo+"\n"+palavrasChave
      puts artigo
    end
  end
  pagina=pagina+1
end
