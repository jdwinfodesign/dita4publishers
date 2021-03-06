/**
 * Copyright 2009, 2010 DITA for Publishers project (dita4publishers.sourceforge.net)  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at     http://www.apache.org/licenses/LICENSE-2.0  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License. 
 */
package net.sourceforge.dita4publishers.impl.dita;

import java.net.MalformedURLException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;

import net.sourceforge.dita4publishers.api.dita.DitaApiException;
import net.sourceforge.dita4publishers.api.dita.DitaFormat;
import net.sourceforge.dita4publishers.api.dita.DitaKeyDefinition;
import net.sourceforge.dita4publishers.api.dita.DitaPropsSpec;
import net.sourceforge.dita4publishers.util.DitaUtil;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
 * See DitaKeyDefinition.
 */
public class DitaKeyDefinitionImpl implements DitaKeyDefinition {
	
	private static Log log = LogFactory.getLog(DitaKeyDefinitionImpl.class);


	private URL absoluteUrl = null;
	private URI baseUri = null;
	private DitaFormat format = DitaFormat.DITA;
	private String href = null;
	private String keyref = null;
	private String key = null;
	private DitaPropsSpec propsSpec;
	private Element keydefElem;
	private Object resource;

	/**
	 * @param document
	 * @param key 
	 * @param keydefElem
	 * @throws URISyntaxException 
	 * @throws MalformedURLException 
	 * @throws DitaApiException 
	 */
	public DitaKeyDefinitionImpl(Document document, String key, Element keydefElem) throws DitaApiException {
		this.keydefElem = keydefElem;
		String baseUriStr = keydefElem.getBaseURI();
		if (baseUriStr == null)
			throw new DitaApiException("keydef element has a null base URI.");
		try {
			this.baseUri = new URI(baseUriStr);
		} catch (URISyntaxException e) {
			throw new DitaApiException(e);
		}		
		this.key = key;
		log.debug("DitaKeyDefinitionImpl(): key=" + key + ", bseUri=" + baseUri);
		if (keydefElem.hasAttribute(DitaUtil.DITA_HREF_ATTNAME)) {
			href = keydefElem.getAttribute(DitaUtil.DITA_HREF_ATTNAME);
			log.debug("DitaKeyDefinitionImpl(): href=\"" + href + "\"");
			try {
				this.absoluteUrl = new URL(baseUri.toURL(), href);
			} catch (MalformedURLException e) {
				throw new DitaApiException(e);
			}
			log.debug("DitaKeyDefinitionImpl(): absoluteUrl=\"" + absoluteUrl + "\"");
		}
		if (keydefElem.hasAttribute(DitaUtil.DITA_KEYREF_ATTNAME)) {
			keyref = keydefElem.getAttribute(DitaUtil.DITA_KEYREF_ATTNAME);
			log.debug("DitaKeyDefinitionImpl(): keyref=\"" + keyref + "\"");
		}
		if (keydefElem.hasAttribute(DitaUtil.DITA_FORMAT_ATTNAME)) {
			String format = keydefElem.getAttribute(DitaUtil.DITA_FORMAT_ATTNAME).toUpperCase();
			log.debug("DitaKeyDefinitionImpl(): format=\"" + format + "\"");
			try {
				this.format = DitaFormat.valueOf(format);
			} catch (Exception e) {
				this.format = DitaFormat.NONDITA;
			}
			
		}
		
		propsSpec = DitaUtil.constructPropsSpec(keydefElem);
	}

	/* (non-Javadoc)
	 * @see com.reallysi.rsuite.api.dita.DitaKeyDefinition#getAbsoluteUri()
	 */
	public URL getAbsoluteUrl() {
		return this.absoluteUrl;
	}

	/* (non-Javadoc)
	 * @see com.reallysi.rsuite.api.dita.DitaKeyDefinition#getBaseUri()
	 */
	public URI getBaseUri() {
		return this.baseUri;
	}

	/* (non-Javadoc)
	 * @see com.reallysi.rsuite.api.dita.DitaKeyDefinition#getFormat()
	 */
	public DitaFormat getFormat() {
		return this.format;
	}

	/* (non-Javadoc)
	 * @see com.reallysi.rsuite.api.dita.DitaKeyDefinition#getHref()
	 */
	public String getHref() {
		return this.href;
	}

	/* (non-Javadoc)
	 * @see com.reallysi.rsuite.api.dita.DitaKeyDefinition#getKeyref()
	 */
	public String getKeyref() {
		return this.keyref;
	}

	/* (non-Javadoc)
	 * @see com.reallysi.rsuite.api.dita.DitaKeyDefinition#getKeys()
	 */
	public String getKey() {
		return this.key;
 	}

	/* (non-Javadoc)
	 * @see java.lang.Comparable#compareTo(java.lang.Object)
	 */
	public int compareTo(DitaKeyDefinition keyDefinition) {
		int result = this.getKey().compareTo(keyDefinition.getKey());
//		if (log.isDebugEnabled())
//			log.debug("compareTo(): returning " + result + " for comparand " + keyDefinition);
		return result;
	}

	/* (non-Javadoc)
	 * @see com.reallysi.rsuite.api.dita.DitaKeyDefinition#equals(com.reallysi.rsuite.api.dita.DitaKeyDefinition)
	 */
	public boolean equals(DitaKeyDefinition keyDefinition) {
		if (keyDefinition.hashCode() == this.hashCode())
			return true;
		boolean result = (this.getKey().equals(keyDefinition.getKey())) &&
		       ((this.getKeyref() == null && keyDefinition.getKeyref() == null) ||
		        (this.getKeyref().equals(keyDefinition.getKeyref()))) &&
		       ((this.getHref() == null && keyDefinition.getHref() == null) || 
		        (this.getAbsoluteUrl().equals(keyDefinition.getAbsoluteUrl())));
//		if (log.isDebugEnabled())
//			log.debug("equals(): returning " + result + " for comparand " + keyDefinition);
		return result;
	}
	
	public String toString() {
		StringBuilder str = new StringBuilder("[DitaKeyDefinitionImpl: key: ")
		.append(this.getKey())
		.append(", href: ");
		if (this.getHref() == null)
			str.append("Not specified");
		else
			str.append(this.getHref());
		str.append(", keyref: ");
		if (this.getKeyref() == null)
			str.append("Not specified");
		else
			str.append(this.keyref);
		str.append("]");
		return str.toString();
	}

	/* (non-Javadoc)
	 * @see net.sourceforge.dita4publishers.api.dita.DitaKeyDefinition#getDitaPropsSpec()
	 */
	public DitaPropsSpec getDitaPropsSpec() {
		return this.propsSpec;
	}

	/* (non-Javadoc)
	 * @see net.sourceforge.dita4publishers.api.dita.DitaKeyDefinition#getKeyDefElem()
	 */
	public Element getKeyDefElem() {
		return this.keydefElem;
	}

	/* (non-Javadoc)
	 * @see net.sourceforge.dita4publishers.api.dita.DitaKeyDefinition#getResource()
	 */
	public Object getResource() {
		return this.resource;
	}

	/* (non-Javadoc)
	 * @see net.sourceforge.dita4publishers.api.dita.DitaKeyDefinition#setResource(java.lang.Object)
	 */
	public void setResource(Object resource) {
		this.resource = resource;
	}

}
