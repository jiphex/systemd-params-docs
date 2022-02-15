require 'logger'
require 'nokogiri'
require 'rugged'
require 'json'

manpage_files = %w[exec unit service socket timer mount resource-control swap kill]
# manpage_files = %w[exec]
versions = 198..250
git_url = 'https://github.com/systemd/systemd.git'

logger = Logger.new STDERR

wd = Dir.mktmpdir 'git-wd'
# wd = './repo'

r = Rugged.clone_at(git_url, 'systemd', path: wd, bare: true)
# r = Rugged::Repository.new "#{wd}/systemd.git"

params = { versions: [], params: {} }

versions.each do |vv|
  logger.info "finding manpages for version #{vv}"
  manpage_files.each do |f|
    begin
      foid = (r.tags.find { |x| x.name == "v#{vv}" }).target.tree.path "man/systemd.#{f}.xml"
      mdata = r.read(foid[:oid]).data
      xf = Nokogiri::XML(mdata)
      entries = xf.xpath('/refentry/refsect1/variablelist[@class!="environment-variables"]/varlistentry')
      entries.each do |e|
        e.xpath('term/varname').each do |ep|
          name = ep.content.split(/=/)[0]
          params[:params][name] = { versions: [], section: '' } if params[:params][name].nil?
          # params[name][:versions] ||= Set.new
          # params[name][:sections] ||= Set.new
          params[:params][name][:versions] << vv
          params[:params][name][:section] = f
          params[:versions] << vv
          # params[name][:sections] << f
        end
      end
      # p entries['title']
      # p mdata
      # g.checkout "v#{vv}"
      # p g.read_tree '/README.md'
    rescue Rugged::TreeError
      logger.warn "skipping version #{vv} due to missing file"
    end
  end
end
params[:versions].uniq!.reverse!
params[:params] = params[:params].sort
puts params.to_json
