require 'net/https'
require 'nokogiri'

url = "https://www.ncbi.nlm.nih.gov/pubmed/?term=diabetes"
url = URI.parse( url )
http = Net::HTTP.new( url.host, url.port )
http.use_ssl = true if url.port == 443
http.verify_mode = OpenSSL::SSL::VERIFY_NONE if url.port == 443
path = url.path
path += "?" + url.query unless url.query.nil?
res, data = http.get( path )

case res
  when Net::HTTPSuccess, Net::HTTPRedirection
    # parse link
    documento = Nokogiri::HTML(data)
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
  else
    puts "failed" + res.to_s

end




