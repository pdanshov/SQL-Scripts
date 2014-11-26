
Nz ( variant, [ value_if_null ] )

myNewValue = IsNull(myValue, new MyValue());

if (myValue == null)
  myValue = new MyValue();
myNewValue = myValue;

myNewValue = myValue ?? new MyValue();

'FalsePart' of 'Public Function IIf(Expression As Boolean, TruePart As Object, FalsePart As Object) As Object'.

--------------------------------------------------------------------------
								Original:
		=Parameters!CustName.Value &
		Chr(13)+Chr(10) & 
		Iif((Parameters!addr1.Value.IsNull)="","",Parameters!addr1.Value 
		& Chr(13)+Chr(10)) & 
		Iif((Parameters!addr2.Value.IsNull)="","",Parameters!addr2.Value 
		& Chr(13)+Chr(10)) & (Parameters!csz.Value.IsNull) & 
		Chr(13)+Chr(10) & 
		IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")
--------------------------------------------------------------------------

=Parameters!CustName.Value & 
Chr(13)+Chr(10) & 
Iif((Parameters!addr1.Value.IsNull)="","",Parameters!addr1.Value & Chr(13)+Chr(10)) &
Iif((Parameters!addr2.Value.IsNull)="","",Parameters!addr2.Value & Chr(13)+Chr(10)) &
Iif(Parameters!csz.Value.IsNull,"",Parameters!csz.Value) &
Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")

=Parameters!CustName.Value & Chr(13)+Chr(10) & Iif((Parameters!addr1.Value.IsNull)="","",Parameters!addr1.Value & Chr(13)+Chr(10)) & Iif((Parameters!addr2.Value.IsNull)="","",Parameters!addr2.Value & Chr(13)+Chr(10)) & Iif(Parameters!csz.Value.IsNull,"",Parameters!csz.Value) & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")

=Parameters!CustName.Value & Chr(13)+Chr(10) & Iif((Parameters!addr1.Value.IsNull)="","",Parameters!addr1.Value & Chr(13)+Chr(10)) & Iif((Parameters!addr2.Value.IsNull)="","",Parameters!addr2.Value & Chr(13)+Chr(10)) & (Parameters!csz.Value.IsNull) & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")

=Parameters!CustName.Value & Chr(13)+Chr(10) & IIf((Parameters!addr1.Value.IsNull)="","",Parameters!addr1.Value & Chr(13)+Chr(10)) & IIf((Parameters!addr2.Value)="","",Parameters!addr2.Value & Chr(13)+Chr(10)) & (Parameters!csz.Value.IsNull,"",Parameters!csz.Value) & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")

=Parameters!CustName.Value & Chr(13)+Chr(10) & Iif(Parameters!addr1.Value.IsNull,"",Parameters!addr1.Value & Chr(13)+Chr(10)) & Iif(Parameters!addr2.Value.IsNull,"",Parameters!addr2.Value & Chr(13)+Chr(10)) & Iif(Parameters!csz.Value.IsNull,"",Parameters!csz.Value) & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")

=Fields!CustName.Value & Chr(13)+Chr(10) & Iif(Fields!addr1.Value.IsNull,"",Fields!addr1.Value & Chr(13)+Chr(10)) & Iif(Fields!addr2.Value.IsNull,"",Fields!addr2.Value & Chr(13)+Chr(10)) & Iif(Fields!csz.Value.IsNull,"",Fields!csz.Value) & Chr(13)+Chr(10) & IIf(Fields!Country.Value<>"US",Fields!Country.Value,"")
=Parameters!CustName.Value & Chr(13)+Chr(10) & IIf(nz(Parameters!addr1.Value,"")="","",Parameters!addr1.Value & Chr(13)+Chr(10)) & IIf(nz(Parameters!addr2.Value,"")="","",Parameters!addr2.Value & Chr(13)+Chr(10)) & nz(Parameters!csz.Value,"") & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")


For example, suppose you have a report that consists of product information pages. In the header of each page, you want to display a photograph of the product. To print a stored image in the report header, define a hidden text box named TXT_Photo in the body of the report that retrieves the image from the database and use an expression to give it a value:
=Convert.ToBase64String(Fields!Photo.Value)
In the header, add an Image report item which uses the TXT_Photo text box, decoded to show the image:
=Convert.FromBase64String(ReportItems!TXT_Photo.Value)

=Left(Parameters!AAEmailAddr.Value,InStr(Parameters!AAEmailAddr.Value,"#")-1)
=Left(Parameters!AAEmailAddr.Value,InStr(Parameters!AAEmailAddr.Value,"#")-1)
=Left(Fields!AAEmailAddr.Value,InStr(Fields!AAEmailAddr.Value,"#")-1)
Properties -> Navigation -> Jump To URL: =Code.GetHyperlink(Fields!AAEmailAddr.Value)
=Code.GetHyperlink(Parameters!AAEmailAddr.Value)


=Fields!CustName.Value & Chr(13)+Chr(10) & Iif(Fields!Addr1.Value.IsNullOrEmpty,"",Fields!Addr1.Value & Chr(13)+Chr(10)) & Iif(Fields!Addr2.Value.IsNullOrEmpty,"",Fields!Addr2.Value & Chr(13)+Chr(10)) & Iif(Fields!CSZ.Value.IsNullOrEmpty,"",Fields!CSZ.Value) & Chr(13)+Chr(10) & IIf(Fields!Country.Value<>"US",Fields!Country.Value,"")
=Parameters!CustName.Value & Chr(13)+Chr(10) & Iif(Parameters!Addr1.Value.IsNull,"",Parameters!Addr1.Value & Chr(13)+Chr(10)) & Iif(Parameters!Addr2.Value.IsNull,"",Parameters!Addr2.Value & Chr(13)+Chr(10)) & Iif(Parameters!CSZ.Value.IsNull,"",Parameters!CSZ.Value) & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")
=CustName.Value & Chr(13)+Chr(10) & Iif(Addr1.Value.IsNull,"",Addr1.Value & Chr(13)+Chr(10)) & Iif(Addr2.Value.IsNull,"",Addr2.Value & Chr(13)+Chr(10)) & Iif(CSZ.Value.IsNull,"",CSZ.Value) & Chr(13)+Chr(10) & IIf(Country.Value<>"US",Country.Value,"")






=Parameters!CustName.Value & Chr(13)+Chr(10) & Iif(Parameters!Addr1.Value.IsNull,"",Parameters!Addr1.Value & Chr(13)+Chr(10)) & Iif(Parameters!Addr2.Value.IsNull,"",Parameters!Addr2.Value & Chr(13)+Chr(10)) & Iif(Parameters!csz.Value.IsNull,"",Parameters!csz.Value) & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")




=Parameters!CustName.Value & Chr(13)+Chr(10) & IIf(nz(Parameters!addr1.Value,"")="","",Parameters!addr1.Value & Chr(13)+Chr(10)) & IIf(nz(Parameters!addr2.Value,"")="","",Parameters!addr2.Value & Chr(13)+Chr(10)) & nz(Parameters!csz.Value,"") & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")


v=Parameters!CustName.Value & Chr(13)+Chr(10) & IIf(Parameters!addr1.Value.IsNull,"",Parameters!addr1.Value & Chr(13)+Chr(10)) & IIf(nz(Parameters!addr2.Value,"")="","",Parameters!addr2.Value & Chr(13)+Chr(10)) & nz(Parameters!csz.Value,"") & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")




=Parameters!CustName.Value & Chr(13)+Chr(10) & IIf(nz(Parameters!addr1.Value,"")="","",Parameters!addr1.Value & Chr(13)+Chr(10)) & IIf(nz(Parameters!addr2.Value,"")="","",Parameters!addr2.Value & Chr(13)+Chr(10)) & nz(Parameters!csz.Value,"") & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")




=Parameters!CustName.Value & Chr(13)+Chr(10) & Iif((Parameters!addr1.Value.IsNull,"",Parameters!addr1.Value)="","",Parameters!addr1.Value & Chr(13)+Chr(10)) & IIf((Parameters!addr2.Value.IsNull,"",Parameters!addr2.Value)="","",Parameters!addr2.Value & Chr(13)+Chr(10)) & Iif(Parameters!csz.Value.IsNull,"",Parameters!csz.Value) & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")

=Parameters!CustName.Value & Chr(13)+Chr(10) & IIf(Iif(Parameters!addr1.Value) ?? "")="","",Parameters!addr1.Value & Chr(13)+Chr(10)) & IIf(Parameters!addr2.Value ?? "")="","",Parameters!addr2.Value & Chr(13)+Chr(10)) & Iif(Parameters!csz.Value ?? "") & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")


=Parameters!CustName.Value & Chr(13)+Chr(10) & IIf(Iif(Is Null([Parameters!addr1.Value]),"",[Parameters!addr1.Value]))="","",Parameters!addr1.Value & Chr(13)+Chr(10)) & IIf(Iif(Is Null([Parameters!addr2.Value]), "",[Parameters!addr2.Value]))="","",Parameters!addr2.Value & Chr(13)+Chr(10)) & Iif(Is Null([Parameters!csz.Value]),"",[Parameters!csz.Value])) & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")


=Parameters!CustName.Value & Chr(13)+Chr(10) & IIf(Iif(Is Null([Parameters!addr1.Value]),"",[Parameters!addr1.Value]))="","",Parameters!addr1.Value & Chr(13)+Chr(10)) & IIf(Iif(Is Null([Parameters!addr2.Value]), "",[Parameters!addr2.Value]))="","",Parameters!addr2.Value & Chr(13)+Chr(10)) & Iif(Is Null([Parameters!csz.Value]),"",[Parameters!csz.Value])) & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")





=Parameters!CustName.Value & Chr(13)+Chr(10) & IIf(Parameters!Addr1.Value,"")="","",Parameters!addr1.Value & Chr(13)+Chr(10)) & IIf(nz(Parameters!addr2.Value,"")="","",Parameters!addr2.Value & Chr(13)+Chr(10)) & nz(Parameters!csz.Value,"") & Chr(13)+Chr(10) & IIf(Parameters!Country.Value<>"US",Parameters!Country.Value,"")




