module SwalFormHelper
  def link_to_swal_form(label, template, opts)
    form = render({template: template}.merge(opts[:render]))
    adjusted_swal_opts = opts[:swal_form].each_with_object({}) {|(k,v), hash| hash["swalform-#{k}"] = v}
    concat content_tag(:div, form, class: "displayNone")
    link_to label, 'javascript:void(0)', class: 'swal-form-link '+opts.dig(:link_opts, :class).to_s, data: adjusted_swal_opts
  end

  def link_to_remote_swal(label, endpoint, opts = {})
    link_to label, endpoint, {remote: true, onclick: "Swal.fire({onOpen: function(){Swal.showLoading();}})"}.merge(opts)
  end
end
