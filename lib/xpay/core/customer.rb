module Xpay

  # The customer is not required for a transaction except for 3D secure transactions in which case
  # http_accept and user_agent are required for ST3DCARDQUERY
  #
  # All other fields are optional and also depend on your security policy with SecureTrading
  #
  # A further note:
  # fullname and firstname + lastname are different and end up in different places in the final xml. You can supply fullname as it appears on the card.

  class Customer

    attr_accessor :title, :fullname, :firstname, :lastname, :middlename, :namesuffix, :companyname,
                  :street, :city, :stateprovince, :postcode, :countrycode,
                  :phone, :email,
                  :http_accept, :user_agent


    def initialize(options={})
      options.each { |key, value| self.send("#{key}=", value) if self.respond_to? key } if (!options.nil? && options.is_a?(Hash))
    end

    def add_to_xml(doc)
      op = REXML::XPath.first(doc, "//Request")
      op.delete_element "CustomerInfo"
      ci = op.add_element "CustomerInfo"
      postal = ci.add_element("Postal")
      name = postal.add_element("Name")
      name.text = self.fullname if self.fullname
      name.add_element("NamePrefix").add_text(self.title) if self.title
      name.add_element("FirstName").add_text(self.firstname) if self.firstname
      name.add_element("MiddleName").add_text(self.middlename) if self.middlename
      name.add_element("LastName").add_text(self.lastname) if self.lastname
      name.add_element("NameSuffix").add_text(self.namesuffix) if self.namesuffix
      postal.add_element("Company").add_text(self.companyname) if self.companyname
      postal.add_element("Street").add_text(self.street) if self.street
      postal.add_element("City").add_text(self.city) if self.city
      postal.add_element("StateProv").add_text(self.stateprovince) if self.stateprovince
      postal.add_element("PostalCode").add_text(self.postcode) if self.postcode
      postal.add_element("CountryCode").add_text(self.countrycode) if self.countrycode
      ci.add_element("Telecom").add_element("Phone").add_text(self.phone) if self.phone
      ci.add_element("Online").add_element("Email").add_text(self.email) if self.email
      ci.add_element("Accept").add_text(self.http_accept) if self.http_accept
      ci.add_element("UserAgent").add_text(self.user_agent) if self.user_agent
    end
  end
end