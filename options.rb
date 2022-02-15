require 'logger'
require 'nokogiri'
require 'rugged'
require 'json'

manpage_files = %w[exec unit service socket timer mount resource-control swap kill]
# manpage_files = %w[exec]
versions = 198..250
git_url = 'https://github.com/systemd/systemd.git'

logger = Logger.new STDERR

# wd = Dir.mktmpdir "git-wd"
wd = './repo'

# repo = Rugged.clone_at(git_url, "systemd", path: wd, bare: true)
r = Rugged::Repository.new "#{wd}/systemd.git"

version_params = {}

versions.each do |vv|
  par = version_params["v#{vv}"] = {}
  logger.info "finding manpages for version #{vv}"
  manpage_files.each do |f|
    begin
      foid = (r.tags.find { |x| x.name == "v#{vv}" }).target.tree.path "man/systemd.#{f}.xml"
      parp = par[f] = []
      mdata = r.read(foid[:oid]).data
      xf = Nokogiri::XML(mdata)
      entries = xf.xpath('/refentry/refsect1/variablelist[@class="unit-directives"]/varlistentry')
      entries.each do |e|
        name = e.xpath('term/varname').first.content
        parp << name
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

puts version_params.to_json
