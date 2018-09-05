# frozen_string_literal: true

class Comfy::Cms::Site < ActiveRecord::Base

  self.table_name = "comfy_cms_sites"

  # -- IH Auto Creation --------------------------------------------------------
  after_create :setup_new_site_associations

  # -- Relationships -----------------------------------------------------------
  with_options dependent: :destroy do |site|
    site.has_many :layouts
    site.has_many :pages
    site.has_many :snippets
    site.has_many :files
    site.has_many :categories
  end

  # -- Callbacks ---------------------------------------------------------------
  before_validation :assign_identifier,
                    :assign_hostname,
                    :assign_label,
                    :clean_path

  # -- Validations -------------------------------------------------------------
  validates :identifier,
    presence:   true,
    uniqueness: true,
    format:     { with: %r{\A\w[a-z0-9_-]*\z}i }
  validates :label,
    presence:   true
  validates :hostname,
    presence:   true,
    uniqueness: { scope: :path },
    format:     { with: %r{\A[\w.-]+(?:\:\d+)?\z} }

  # -- Class Methods -----------------------------------------------------------
  # returning the Comfy::Cms::Site instance based on host and path
  def self.find_site(host, path = nil)
    return Comfy::Cms::Site.first if Comfy::Cms::Site.count == 1
    cms_site = nil

    public_cms_path = ComfortableMexicanSofa.configuration.public_cms_path
    if path && public_cms_path != "/"
      path = path.sub(%r{\A#{public_cms_path}}, "")
    end

    Comfy::Cms::Site.where(hostname: real_host_from_aliases(host)).each do |site|
      if site.path.blank?
        cms_site = site
      elsif "#{path.to_s.split('?')[0]}/" =~ %r{^/#{Regexp.escape(site.path.to_s)}/}
        cms_site = site
        break
      end
    end
    cms_site
  end

  def self.real_host_from_aliases(host)
    if (aliases = ComfortableMexicanSofa.config.hostname_aliases)
      aliases.each do |alias_host, hosts|
        return alias_host if hosts.include?(host)
      end
    end
    host
  end

  # -- Instance Methods --------------------------------------------------------
  def url(relative: false)
    public_cms_path = ComfortableMexicanSofa.config.public_cms_path || "/"
    host = "//#{hostname}"
    path = ["/", public_cms_path, self.path].compact.join("/").squeeze("/").chomp("/")
    relative ? path.presence : [host, path].join
  end

protected

  def setup_new_site_associations
    # setup layout and page
    layout = self.layouts.create({
      app_layout: 'application',
      label: 'Checkin Layout',
      identifier: 'checkin-layout',
      position: 0,
      js: '',
      css: '',
      content: "<article class=\"dashboard-content dashboard-page container\">\r\n  <section class=\"section pt-0\">\r\n    <div class=\"row main-row\">\r\n      <div class=\"col-md-4 hidden-xs-down\">\r\n        {{ cms:partial \"cms/nav\" }}\r\n      </div>\r\n      <div class=\"col-md-8 col-xs-12 border-left h-100\">\r\n        <div class=\"pure-container\" data-effect=\"pure-effect-slide\">\r\n          <input type=\"checkbox\" id=\"pure-toggle-right\" class=\"pure-toggle\" data-toggle=\"right\">\r\n          <label class=\"pure-toggle-label\" for=\"pure-toggle-right\" data-toggle-label=\"right\">\r\n            <span class=\"pure-toggle-icon\"></span>\r\n          </label>\r\n          <div class=\"pure-drawer\" data-position=\"right\">\r\n            {{ cms:partial \"cms/drawer\" }}\r\n          </div>\r\n          <div class=\"pure-pusher-container\">\r\n            <div class=\"pure-pusher\">\r\n              {{ cms:wysiwyg content }}\r\n            </div>\r\n          </div>\r\n          <label class=\"pure-overlay\" for=\"pure-toggle-right\" data-overlay=\"right\"></label>\r\n        </div>\r\n      </div>\r\n    </div>\r\n  </section>\r\n</article>"
    })
    self.pages.create({
      layout: layout,
      label: self.label,
      full_path: '/',
      position: 0,
      is_published: true
    })
  end

  def assign_identifier
    self.identifier = identifier.blank? ? hostname.try(:parameterize) : identifier
  end

  def assign_hostname
    self.hostname ||= identifier
  end

  def assign_label
    self.label = label.blank? ? identifier.try(:titleize) : label
  end

  def clean_path
    self.path ||= ""
    self.path.squeeze!("/")
    self.path.gsub!(%r{/$}, "")
    self.path = nil if self.path.blank?
  end

end
