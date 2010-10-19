module Xpay
  class Customer
    attr_accessor :title, :fullname, :firstname, :lastname, :middlename, :namesuffix, :companyname,
                  :street, :city, :stateprovince, :postcode, :countrycode,
                  :phone, :email

    def add_to_xml(doc)
      op = REXML::XPath.first(doc, "//Operation")
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
      return doc
    end
  end
end