var AvfxPlayer=(function(e){Object.defineProperty(e,Symbol.toStringTag,{value:`Module`});var t={LEFT:0,MIDDLE:1,RIGHT:2,ROTATE:0,DOLLY:1,PAN:2},n={ROTATE:0,PAN:1,DOLLY_PAN:2,DOLLY_ROTATE:3},r=1e3,i=1001,a=1002,o=1003,s=1004,c=1005,l=1006,u=1007,d=1008,f=1009,p=1010,m=1011,h=1012,g=1013,_=1014,v=1015,y=1016,b=1017,x=1018,S=1020,C=35902,w=1021,T=1022,E=1023,D=1024,O=1025,k=1026,ee=1027,A=1028,te=1029,ne=1030,j=1031,M=1033,N=33776,re=33777,ie=33778,ae=33779,oe=35840,se=35841,ce=35842,le=35843,ue=36196,de=37492,fe=37496,pe=37808,me=37809,he=37810,ge=37811,_e=37812,P=37813,ve=37814,ye=37815,be=37816,F=37817,xe=37818,I=37819,L=37820,Se=37821,Ce=36492,we=36494,Te=36495,Ee=36283,De=36284,Oe=36285,ke=36286,Ae=2300,je=2301,Me=2302,Ne=2400,Pe=2401,Fe=2402,Ie=3200,Le=3201,Re=`srgb`,ze=`srgb-linear`,Be=`linear`,Ve=`srgb`,He=7680,Ue=35044,We=2e3,Ge=class{addEventListener(e,t){this._listeners===void 0&&(this._listeners={});let n=this._listeners;n[e]===void 0&&(n[e]=[]),n[e].indexOf(t)===-1&&n[e].push(t)}hasEventListener(e,t){if(this._listeners===void 0)return!1;let n=this._listeners;return n[e]!==void 0&&n[e].indexOf(t)!==-1}removeEventListener(e,t){if(this._listeners===void 0)return;let n=this._listeners[e];if(n!==void 0){let e=n.indexOf(t);e!==-1&&n.splice(e,1)}}dispatchEvent(e){if(this._listeners===void 0)return;let t=this._listeners[e.type];if(t!==void 0){e.target=this;let n=t.slice(0);for(let t=0,r=n.length;t<r;t++)n[t].call(this,e);e.target=null}}},Ke=`00.01.02.03.04.05.06.07.08.09.0a.0b.0c.0d.0e.0f.10.11.12.13.14.15.16.17.18.19.1a.1b.1c.1d.1e.1f.20.21.22.23.24.25.26.27.28.29.2a.2b.2c.2d.2e.2f.30.31.32.33.34.35.36.37.38.39.3a.3b.3c.3d.3e.3f.40.41.42.43.44.45.46.47.48.49.4a.4b.4c.4d.4e.4f.50.51.52.53.54.55.56.57.58.59.5a.5b.5c.5d.5e.5f.60.61.62.63.64.65.66.67.68.69.6a.6b.6c.6d.6e.6f.70.71.72.73.74.75.76.77.78.79.7a.7b.7c.7d.7e.7f.80.81.82.83.84.85.86.87.88.89.8a.8b.8c.8d.8e.8f.90.91.92.93.94.95.96.97.98.99.9a.9b.9c.9d.9e.9f.a0.a1.a2.a3.a4.a5.a6.a7.a8.a9.aa.ab.ac.ad.ae.af.b0.b1.b2.b3.b4.b5.b6.b7.b8.b9.ba.bb.bc.bd.be.bf.c0.c1.c2.c3.c4.c5.c6.c7.c8.c9.ca.cb.cc.cd.ce.cf.d0.d1.d2.d3.d4.d5.d6.d7.d8.d9.da.db.dc.dd.de.df.e0.e1.e2.e3.e4.e5.e6.e7.e8.e9.ea.eb.ec.ed.ee.ef.f0.f1.f2.f3.f4.f5.f6.f7.f8.f9.fa.fb.fc.fd.fe.ff`.split(`.`),qe=1234567,Je=Math.PI/180,Ye=180/Math.PI;function Xe(){let e=Math.random()*4294967295|0,t=Math.random()*4294967295|0,n=Math.random()*4294967295|0,r=Math.random()*4294967295|0;return(Ke[e&255]+Ke[e>>8&255]+Ke[e>>16&255]+Ke[e>>24&255]+`-`+Ke[t&255]+Ke[t>>8&255]+`-`+Ke[t>>16&15|64]+Ke[t>>24&255]+`-`+Ke[n&63|128]+Ke[n>>8&255]+`-`+Ke[n>>16&255]+Ke[n>>24&255]+Ke[r&255]+Ke[r>>8&255]+Ke[r>>16&255]+Ke[r>>24&255]).toLowerCase()}function Ze(e,t,n){return Math.max(t,Math.min(n,e))}function Qe(e,t){return(e%t+t)%t}function $e(e,t,n,r,i){return r+(e-t)*(i-r)/(n-t)}function et(e,t,n){return e===t?0:(n-e)/(t-e)}function tt(e,t,n){return(1-n)*e+n*t}function nt(e,t,n,r){return tt(e,t,1-Math.exp(-n*r))}function rt(e,t=1){return t-Math.abs(Qe(e,t*2)-t)}function it(e,t,n){return e<=t?0:e>=n?1:(e=(e-t)/(n-t),e*e*(3-2*e))}function at(e,t,n){return e<=t?0:e>=n?1:(e=(e-t)/(n-t),e*e*e*(e*(e*6-15)+10))}function ot(e,t){return e+Math.floor(Math.random()*(t-e+1))}function st(e,t){return e+Math.random()*(t-e)}function ct(e){return e*(.5-Math.random())}function lt(e){e!==void 0&&(qe=e);let t=qe+=1831565813;return t=Math.imul(t^t>>>15,t|1),t^=t+Math.imul(t^t>>>7,t|61),((t^t>>>14)>>>0)/4294967296}function ut(e){return e*Je}function dt(e){return e*Ye}function ft(e){return!(e&e-1)&&e!==0}function pt(e){return 2**Math.ceil(Math.log(e)/Math.LN2)}function mt(e){return 2**Math.floor(Math.log(e)/Math.LN2)}function ht(e,t,n,r,i){let a=Math.cos,o=Math.sin,s=a(n/2),c=o(n/2),l=a((t+r)/2),u=o((t+r)/2),d=a((t-r)/2),f=o((t-r)/2),p=a((r-t)/2),m=o((r-t)/2);switch(i){case`XYX`:e.set(s*u,c*d,c*f,s*l);break;case`YZY`:e.set(c*f,s*u,c*d,s*l);break;case`ZXZ`:e.set(c*d,c*f,s*u,s*l);break;case`XZX`:e.set(s*u,c*m,c*p,s*l);break;case`YXY`:e.set(c*p,s*u,c*m,s*l);break;case`ZYZ`:e.set(c*m,c*p,s*u,s*l);break;default:console.warn(`THREE.MathUtils: .setQuaternionFromProperEuler() encountered an unknown order: `+i)}}function gt(e,t){switch(t.constructor){case Float32Array:return e;case Uint32Array:return e/4294967295;case Uint16Array:return e/65535;case Uint8Array:return e/255;case Int32Array:return Math.max(e/2147483647,-1);case Int16Array:return Math.max(e/32767,-1);case Int8Array:return Math.max(e/127,-1);default:throw Error(`Invalid component type.`)}}function _t(e,t){switch(t.constructor){case Float32Array:return e;case Uint32Array:return Math.round(e*4294967295);case Uint16Array:return Math.round(e*65535);case Uint8Array:return Math.round(e*255);case Int32Array:return Math.round(e*2147483647);case Int16Array:return Math.round(e*32767);case Int8Array:return Math.round(e*127);default:throw Error(`Invalid component type.`)}}var vt={DEG2RAD:Je,RAD2DEG:Ye,generateUUID:Xe,clamp:Ze,euclideanModulo:Qe,mapLinear:$e,inverseLerp:et,lerp:tt,damp:nt,pingpong:rt,smoothstep:it,smootherstep:at,randInt:ot,randFloat:st,randFloatSpread:ct,seededRandom:lt,degToRad:ut,radToDeg:dt,isPowerOfTwo:ft,ceilPowerOfTwo:pt,floorPowerOfTwo:mt,setQuaternionFromProperEuler:ht,normalize:_t,denormalize:gt},R=class e{constructor(t=0,n=0){e.prototype.isVector2=!0,this.x=t,this.y=n}get width(){return this.x}set width(e){this.x=e}get height(){return this.y}set height(e){this.y=e}set(e,t){return this.x=e,this.y=t,this}setScalar(e){return this.x=e,this.y=e,this}setX(e){return this.x=e,this}setY(e){return this.y=e,this}setComponent(e,t){switch(e){case 0:this.x=t;break;case 1:this.y=t;break;default:throw Error(`index is out of range: `+e)}return this}getComponent(e){switch(e){case 0:return this.x;case 1:return this.y;default:throw Error(`index is out of range: `+e)}}clone(){return new this.constructor(this.x,this.y)}copy(e){return this.x=e.x,this.y=e.y,this}add(e){return this.x+=e.x,this.y+=e.y,this}addScalar(e){return this.x+=e,this.y+=e,this}addVectors(e,t){return this.x=e.x+t.x,this.y=e.y+t.y,this}addScaledVector(e,t){return this.x+=e.x*t,this.y+=e.y*t,this}sub(e){return this.x-=e.x,this.y-=e.y,this}subScalar(e){return this.x-=e,this.y-=e,this}subVectors(e,t){return this.x=e.x-t.x,this.y=e.y-t.y,this}multiply(e){return this.x*=e.x,this.y*=e.y,this}multiplyScalar(e){return this.x*=e,this.y*=e,this}divide(e){return this.x/=e.x,this.y/=e.y,this}divideScalar(e){return this.multiplyScalar(1/e)}applyMatrix3(e){let t=this.x,n=this.y,r=e.elements;return this.x=r[0]*t+r[3]*n+r[6],this.y=r[1]*t+r[4]*n+r[7],this}min(e){return this.x=Math.min(this.x,e.x),this.y=Math.min(this.y,e.y),this}max(e){return this.x=Math.max(this.x,e.x),this.y=Math.max(this.y,e.y),this}clamp(e,t){return this.x=Math.max(e.x,Math.min(t.x,this.x)),this.y=Math.max(e.y,Math.min(t.y,this.y)),this}clampScalar(e,t){return this.x=Math.max(e,Math.min(t,this.x)),this.y=Math.max(e,Math.min(t,this.y)),this}clampLength(e,t){let n=this.length();return this.divideScalar(n||1).multiplyScalar(Math.max(e,Math.min(t,n)))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this}negate(){return this.x=-this.x,this.y=-this.y,this}dot(e){return this.x*e.x+this.y*e.y}cross(e){return this.x*e.y-this.y*e.x}lengthSq(){return this.x*this.x+this.y*this.y}length(){return Math.sqrt(this.x*this.x+this.y*this.y)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)}normalize(){return this.divideScalar(this.length()||1)}angle(){return Math.atan2(-this.y,-this.x)+Math.PI}angleTo(e){let t=Math.sqrt(this.lengthSq()*e.lengthSq());if(t===0)return Math.PI/2;let n=this.dot(e)/t;return Math.acos(Ze(n,-1,1))}distanceTo(e){return Math.sqrt(this.distanceToSquared(e))}distanceToSquared(e){let t=this.x-e.x,n=this.y-e.y;return t*t+n*n}manhattanDistanceTo(e){return Math.abs(this.x-e.x)+Math.abs(this.y-e.y)}setLength(e){return this.normalize().multiplyScalar(e)}lerp(e,t){return this.x+=(e.x-this.x)*t,this.y+=(e.y-this.y)*t,this}lerpVectors(e,t,n){return this.x=e.x+(t.x-e.x)*n,this.y=e.y+(t.y-e.y)*n,this}equals(e){return e.x===this.x&&e.y===this.y}fromArray(e,t=0){return this.x=e[t],this.y=e[t+1],this}toArray(e=[],t=0){return e[t]=this.x,e[t+1]=this.y,e}fromBufferAttribute(e,t){return this.x=e.getX(t),this.y=e.getY(t),this}rotateAround(e,t){let n=Math.cos(t),r=Math.sin(t),i=this.x-e.x,a=this.y-e.y;return this.x=i*n-a*r+e.x,this.y=i*r+a*n+e.y,this}random(){return this.x=Math.random(),this.y=Math.random(),this}*[Symbol.iterator](){yield this.x,yield this.y}},z=class e{constructor(t,n,r,i,a,o,s,c,l){e.prototype.isMatrix3=!0,this.elements=[1,0,0,0,1,0,0,0,1],t!==void 0&&this.set(t,n,r,i,a,o,s,c,l)}set(e,t,n,r,i,a,o,s,c){let l=this.elements;return l[0]=e,l[1]=r,l[2]=o,l[3]=t,l[4]=i,l[5]=s,l[6]=n,l[7]=a,l[8]=c,this}identity(){return this.set(1,0,0,0,1,0,0,0,1),this}copy(e){let t=this.elements,n=e.elements;return t[0]=n[0],t[1]=n[1],t[2]=n[2],t[3]=n[3],t[4]=n[4],t[5]=n[5],t[6]=n[6],t[7]=n[7],t[8]=n[8],this}extractBasis(e,t,n){return e.setFromMatrix3Column(this,0),t.setFromMatrix3Column(this,1),n.setFromMatrix3Column(this,2),this}setFromMatrix4(e){let t=e.elements;return this.set(t[0],t[4],t[8],t[1],t[5],t[9],t[2],t[6],t[10]),this}multiply(e){return this.multiplyMatrices(this,e)}premultiply(e){return this.multiplyMatrices(e,this)}multiplyMatrices(e,t){let n=e.elements,r=t.elements,i=this.elements,a=n[0],o=n[3],s=n[6],c=n[1],l=n[4],u=n[7],d=n[2],f=n[5],p=n[8],m=r[0],h=r[3],g=r[6],_=r[1],v=r[4],y=r[7],b=r[2],x=r[5],S=r[8];return i[0]=a*m+o*_+s*b,i[3]=a*h+o*v+s*x,i[6]=a*g+o*y+s*S,i[1]=c*m+l*_+u*b,i[4]=c*h+l*v+u*x,i[7]=c*g+l*y+u*S,i[2]=d*m+f*_+p*b,i[5]=d*h+f*v+p*x,i[8]=d*g+f*y+p*S,this}multiplyScalar(e){let t=this.elements;return t[0]*=e,t[3]*=e,t[6]*=e,t[1]*=e,t[4]*=e,t[7]*=e,t[2]*=e,t[5]*=e,t[8]*=e,this}determinant(){let e=this.elements,t=e[0],n=e[1],r=e[2],i=e[3],a=e[4],o=e[5],s=e[6],c=e[7],l=e[8];return t*a*l-t*o*c-n*i*l+n*o*s+r*i*c-r*a*s}invert(){let e=this.elements,t=e[0],n=e[1],r=e[2],i=e[3],a=e[4],o=e[5],s=e[6],c=e[7],l=e[8],u=l*a-o*c,d=o*s-l*i,f=c*i-a*s,p=t*u+n*d+r*f;if(p===0)return this.set(0,0,0,0,0,0,0,0,0);let m=1/p;return e[0]=u*m,e[1]=(r*c-l*n)*m,e[2]=(o*n-r*a)*m,e[3]=d*m,e[4]=(l*t-r*s)*m,e[5]=(r*i-o*t)*m,e[6]=f*m,e[7]=(n*s-c*t)*m,e[8]=(a*t-n*i)*m,this}transpose(){let e,t=this.elements;return e=t[1],t[1]=t[3],t[3]=e,e=t[2],t[2]=t[6],t[6]=e,e=t[5],t[5]=t[7],t[7]=e,this}getNormalMatrix(e){return this.setFromMatrix4(e).invert().transpose()}transposeIntoArray(e){let t=this.elements;return e[0]=t[0],e[1]=t[3],e[2]=t[6],e[3]=t[1],e[4]=t[4],e[5]=t[7],e[6]=t[2],e[7]=t[5],e[8]=t[8],this}setUvTransform(e,t,n,r,i,a,o){let s=Math.cos(i),c=Math.sin(i);return this.set(n*s,n*c,-n*(s*a+c*o)+a+e,-r*c,r*s,-r*(-c*a+s*o)+o+t,0,0,1),this}scale(e,t){return this.premultiply(yt.makeScale(e,t)),this}rotate(e){return this.premultiply(yt.makeRotation(-e)),this}translate(e,t){return this.premultiply(yt.makeTranslation(e,t)),this}makeTranslation(e,t){return e.isVector2?this.set(1,0,e.x,0,1,e.y,0,0,1):this.set(1,0,e,0,1,t,0,0,1),this}makeRotation(e){let t=Math.cos(e),n=Math.sin(e);return this.set(t,-n,0,n,t,0,0,0,1),this}makeScale(e,t){return this.set(e,0,0,0,t,0,0,0,1),this}equals(e){let t=this.elements,n=e.elements;for(let e=0;e<9;e++)if(t[e]!==n[e])return!1;return!0}fromArray(e,t=0){for(let n=0;n<9;n++)this.elements[n]=e[n+t];return this}toArray(e=[],t=0){let n=this.elements;return e[t]=n[0],e[t+1]=n[1],e[t+2]=n[2],e[t+3]=n[3],e[t+4]=n[4],e[t+5]=n[5],e[t+6]=n[6],e[t+7]=n[7],e[t+8]=n[8],e}clone(){return new this.constructor().fromArray(this.elements)}},yt=new z;function bt(e){for(let t=e.length-1;t>=0;--t)if(e[t]>=65535)return!0;return!1}function xt(e){return document.createElementNS(`http://www.w3.org/1999/xhtml`,e)}function St(){let e=xt(`canvas`);return e.style.display=`block`,e}var Ct={};function wt(e){e in Ct||(Ct[e]=!0,console.warn(e))}function Tt(e,t,n){return new Promise(function(r,i){function a(){switch(e.clientWaitSync(t,e.SYNC_FLUSH_COMMANDS_BIT,0)){case e.WAIT_FAILED:i();break;case e.TIMEOUT_EXPIRED:setTimeout(a,n);break;default:r()}}setTimeout(a,n)})}function Et(e){let t=e.elements;t[2]=.5*t[2]+.5*t[3],t[6]=.5*t[6]+.5*t[7],t[10]=.5*t[10]+.5*t[11],t[14]=.5*t[14]+.5*t[15]}function Dt(e){let t=e.elements;t[11]===-1?(t[10]=-t[10]-1,t[14]=-t[14]):(t[10]=-t[10],t[14]=-t[14]+1)}var Ot={enabled:!0,workingColorSpace:ze,spaces:{},convert:function(e,t,n){return this.enabled===!1||t===n||!t||!n?e:(this.spaces[t].transfer===`srgb`&&(e.r=kt(e.r),e.g=kt(e.g),e.b=kt(e.b)),this.spaces[t].primaries!==this.spaces[n].primaries&&(e.applyMatrix3(this.spaces[t].toXYZ),e.applyMatrix3(this.spaces[n].fromXYZ)),this.spaces[n].transfer===`srgb`&&(e.r=At(e.r),e.g=At(e.g),e.b=At(e.b)),e)},fromWorkingColorSpace:function(e,t){return this.convert(e,this.workingColorSpace,t)},toWorkingColorSpace:function(e,t){return this.convert(e,t,this.workingColorSpace)},getPrimaries:function(e){return this.spaces[e].primaries},getTransfer:function(e){return e===``?Be:this.spaces[e].transfer},getLuminanceCoefficients:function(e,t=this.workingColorSpace){return e.fromArray(this.spaces[t].luminanceCoefficients)},define:function(e){Object.assign(this.spaces,e)},_getMatrix:function(e,t,n){return e.copy(this.spaces[t].toXYZ).multiply(this.spaces[n].fromXYZ)},_getDrawingBufferColorSpace:function(e){return this.spaces[e].outputColorSpaceConfig.drawingBufferColorSpace},_getUnpackColorSpace:function(e=this.workingColorSpace){return this.spaces[e].workingColorSpaceConfig.unpackColorSpace}};function kt(e){return e<.04045?e*.0773993808:(e*.9478672986+.0521327014)**2.4}function At(e){return e<.0031308?e*12.92:1.055*e**.41666-.055}var jt=[.64,.33,.3,.6,.15,.06],Mt=[.2126,.7152,.0722],Nt=[.3127,.329],Pt=new z().set(.4123908,.3575843,.1804808,.212639,.7151687,.0721923,.0193308,.1191948,.9505322),Ft=new z().set(3.2409699,-1.5373832,-.4986108,-.9692436,1.8759675,.0415551,.0556301,-.203977,1.0569715);Ot.define({[ze]:{primaries:jt,whitePoint:Nt,transfer:Be,toXYZ:Pt,fromXYZ:Ft,luminanceCoefficients:Mt,workingColorSpaceConfig:{unpackColorSpace:Re},outputColorSpaceConfig:{drawingBufferColorSpace:Re}},[Re]:{primaries:jt,whitePoint:Nt,transfer:Ve,toXYZ:Pt,fromXYZ:Ft,luminanceCoefficients:Mt,outputColorSpaceConfig:{drawingBufferColorSpace:Re}}});var It,Lt=class{static getDataURL(e){if(/^data:/i.test(e.src)||typeof HTMLCanvasElement>`u`)return e.src;let t;if(e instanceof HTMLCanvasElement)t=e;else{It===void 0&&(It=xt(`canvas`)),It.width=e.width,It.height=e.height;let n=It.getContext(`2d`);e instanceof ImageData?n.putImageData(e,0,0):n.drawImage(e,0,0,e.width,e.height),t=It}return t.width>2048||t.height>2048?(console.warn(`THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons`,e),t.toDataURL(`image/jpeg`,.6)):t.toDataURL(`image/png`)}static sRGBToLinear(e){if(typeof HTMLImageElement<`u`&&e instanceof HTMLImageElement||typeof HTMLCanvasElement<`u`&&e instanceof HTMLCanvasElement||typeof ImageBitmap<`u`&&e instanceof ImageBitmap){let t=xt(`canvas`);t.width=e.width,t.height=e.height;let n=t.getContext(`2d`);n.drawImage(e,0,0,e.width,e.height);let r=n.getImageData(0,0,e.width,e.height),i=r.data;for(let e=0;e<i.length;e++)i[e]=kt(i[e]/255)*255;return n.putImageData(r,0,0),t}if(e.data){let t=e.data.slice(0);for(let e=0;e<t.length;e++)t instanceof Uint8Array||t instanceof Uint8ClampedArray?t[e]=Math.floor(kt(t[e]/255)*255):t[e]=kt(t[e]);return{data:t,width:e.width,height:e.height}}return console.warn(`THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied.`),e}},Rt=0,zt=class{constructor(e=null){this.isSource=!0,Object.defineProperty(this,"id",{value:Rt++}),this.uuid=Xe(),this.data=e,this.dataReady=!0,this.version=0}set needsUpdate(e){e===!0&&this.version++}toJSON(e){let t=e===void 0||typeof e==`string`;if(!t&&e.images[this.uuid]!==void 0)return e.images[this.uuid];let n={uuid:this.uuid,url:``},r=this.data;if(r!==null){let e;if(Array.isArray(r)){e=[];for(let t=0,n=r.length;t<n;t++)r[t].isDataTexture?e.push(Bt(r[t].image)):e.push(Bt(r[t]))}else e=Bt(r);n.url=e}return t||(e.images[this.uuid]=n),n}};function Bt(e){return typeof HTMLImageElement<`u`&&e instanceof HTMLImageElement||typeof HTMLCanvasElement<`u`&&e instanceof HTMLCanvasElement||typeof ImageBitmap<`u`&&e instanceof ImageBitmap?Lt.getDataURL(e):e.data?{data:Array.from(e.data),width:e.width,height:e.height,type:e.data.constructor.name}:(console.warn(`THREE.Texture: Unable to serialize Texture.`),{})}var Vt=0,Ht=class e extends Ge{constructor(t=e.DEFAULT_IMAGE,n=e.DEFAULT_MAPPING,r=i,a=i,o=l,s=d,c=E,u=f,p=e.DEFAULT_ANISOTROPY,m=``){super(),this.isTexture=!0,Object.defineProperty(this,"id",{value:Vt++}),this.uuid=Xe(),this.name=``,this.source=new zt(t),this.mipmaps=[],this.mapping=n,this.channel=0,this.wrapS=r,this.wrapT=a,this.magFilter=o,this.minFilter=s,this.anisotropy=p,this.format=c,this.internalFormat=null,this.type=u,this.offset=new R(0,0),this.repeat=new R(1,1),this.center=new R(0,0),this.rotation=0,this.matrixAutoUpdate=!0,this.matrix=new z,this.generateMipmaps=!0,this.premultiplyAlpha=!1,this.flipY=!0,this.unpackAlignment=4,this.colorSpace=m,this.userData={},this.version=0,this.onUpdate=null,this.isRenderTargetTexture=!1,this.pmremVersion=0}get image(){return this.source.data}set image(e=null){this.source.data=e}updateMatrix(){this.matrix.setUvTransform(this.offset.x,this.offset.y,this.repeat.x,this.repeat.y,this.rotation,this.center.x,this.center.y)}clone(){return new this.constructor().copy(this)}copy(e){return this.name=e.name,this.source=e.source,this.mipmaps=e.mipmaps.slice(0),this.mapping=e.mapping,this.channel=e.channel,this.wrapS=e.wrapS,this.wrapT=e.wrapT,this.magFilter=e.magFilter,this.minFilter=e.minFilter,this.anisotropy=e.anisotropy,this.format=e.format,this.internalFormat=e.internalFormat,this.type=e.type,this.offset.copy(e.offset),this.repeat.copy(e.repeat),this.center.copy(e.center),this.rotation=e.rotation,this.matrixAutoUpdate=e.matrixAutoUpdate,this.matrix.copy(e.matrix),this.generateMipmaps=e.generateMipmaps,this.premultiplyAlpha=e.premultiplyAlpha,this.flipY=e.flipY,this.unpackAlignment=e.unpackAlignment,this.colorSpace=e.colorSpace,this.userData=JSON.parse(JSON.stringify(e.userData)),this.needsUpdate=!0,this}toJSON(e){let t=e===void 0||typeof e==`string`;if(!t&&e.textures[this.uuid]!==void 0)return e.textures[this.uuid];let n={metadata:{version:4.6,type:`Texture`,generator:`Texture.toJSON`},uuid:this.uuid,name:this.name,image:this.source.toJSON(e).uuid,mapping:this.mapping,channel:this.channel,repeat:[this.repeat.x,this.repeat.y],offset:[this.offset.x,this.offset.y],center:[this.center.x,this.center.y],rotation:this.rotation,wrap:[this.wrapS,this.wrapT],format:this.format,internalFormat:this.internalFormat,type:this.type,colorSpace:this.colorSpace,minFilter:this.minFilter,magFilter:this.magFilter,anisotropy:this.anisotropy,flipY:this.flipY,generateMipmaps:this.generateMipmaps,premultiplyAlpha:this.premultiplyAlpha,unpackAlignment:this.unpackAlignment};return Object.keys(this.userData).length>0&&(n.userData=this.userData),t||(e.textures[this.uuid]=n),n}dispose(){this.dispatchEvent({type:`dispose`})}transformUv(e){if(this.mapping!==300)return e;if(e.applyMatrix3(this.matrix),e.x<0||e.x>1)switch(this.wrapS){case r:e.x-=Math.floor(e.x);break;case i:e.x=e.x<0?0:1;break;case a:Math.abs(Math.floor(e.x)%2)===1?e.x=Math.ceil(e.x)-e.x:e.x-=Math.floor(e.x)}if(e.y<0||e.y>1)switch(this.wrapT){case r:e.y-=Math.floor(e.y);break;case i:e.y=e.y<0?0:1;break;case a:Math.abs(Math.floor(e.y)%2)===1?e.y=Math.ceil(e.y)-e.y:e.y-=Math.floor(e.y)}return this.flipY&&(e.y=1-e.y),e}set needsUpdate(e){e===!0&&(this.version++,this.source.needsUpdate=!0)}set needsPMREMUpdate(e){e===!0&&this.pmremVersion++}};Ht.DEFAULT_IMAGE=null,Ht.DEFAULT_MAPPING=300,Ht.DEFAULT_ANISOTROPY=1;var B=class e{constructor(t=0,n=0,r=0,i=1){e.prototype.isVector4=!0,this.x=t,this.y=n,this.z=r,this.w=i}get width(){return this.z}set width(e){this.z=e}get height(){return this.w}set height(e){this.w=e}set(e,t,n,r){return this.x=e,this.y=t,this.z=n,this.w=r,this}setScalar(e){return this.x=e,this.y=e,this.z=e,this.w=e,this}setX(e){return this.x=e,this}setY(e){return this.y=e,this}setZ(e){return this.z=e,this}setW(e){return this.w=e,this}setComponent(e,t){switch(e){case 0:this.x=t;break;case 1:this.y=t;break;case 2:this.z=t;break;case 3:this.w=t;break;default:throw Error(`index is out of range: `+e)}return this}getComponent(e){switch(e){case 0:return this.x;case 1:return this.y;case 2:return this.z;case 3:return this.w;default:throw Error(`index is out of range: `+e)}}clone(){return new this.constructor(this.x,this.y,this.z,this.w)}copy(e){return this.x=e.x,this.y=e.y,this.z=e.z,this.w=e.w===void 0?1:e.w,this}add(e){return this.x+=e.x,this.y+=e.y,this.z+=e.z,this.w+=e.w,this}addScalar(e){return this.x+=e,this.y+=e,this.z+=e,this.w+=e,this}addVectors(e,t){return this.x=e.x+t.x,this.y=e.y+t.y,this.z=e.z+t.z,this.w=e.w+t.w,this}addScaledVector(e,t){return this.x+=e.x*t,this.y+=e.y*t,this.z+=e.z*t,this.w+=e.w*t,this}sub(e){return this.x-=e.x,this.y-=e.y,this.z-=e.z,this.w-=e.w,this}subScalar(e){return this.x-=e,this.y-=e,this.z-=e,this.w-=e,this}subVectors(e,t){return this.x=e.x-t.x,this.y=e.y-t.y,this.z=e.z-t.z,this.w=e.w-t.w,this}multiply(e){return this.x*=e.x,this.y*=e.y,this.z*=e.z,this.w*=e.w,this}multiplyScalar(e){return this.x*=e,this.y*=e,this.z*=e,this.w*=e,this}applyMatrix4(e){let t=this.x,n=this.y,r=this.z,i=this.w,a=e.elements;return this.x=a[0]*t+a[4]*n+a[8]*r+a[12]*i,this.y=a[1]*t+a[5]*n+a[9]*r+a[13]*i,this.z=a[2]*t+a[6]*n+a[10]*r+a[14]*i,this.w=a[3]*t+a[7]*n+a[11]*r+a[15]*i,this}divide(e){return this.x/=e.x,this.y/=e.y,this.z/=e.z,this.w/=e.w,this}divideScalar(e){return this.multiplyScalar(1/e)}setAxisAngleFromQuaternion(e){this.w=2*Math.acos(e.w);let t=Math.sqrt(1-e.w*e.w);return t<1e-4?(this.x=1,this.y=0,this.z=0):(this.x=e.x/t,this.y=e.y/t,this.z=e.z/t),this}setAxisAngleFromRotationMatrix(e){let t,n,r,i,a=.01,o=.1,s=e.elements,c=s[0],l=s[4],u=s[8],d=s[1],f=s[5],p=s[9],m=s[2],h=s[6],g=s[10];if(Math.abs(l-d)<a&&Math.abs(u-m)<a&&Math.abs(p-h)<a){if(Math.abs(l+d)<o&&Math.abs(u+m)<o&&Math.abs(p+h)<o&&Math.abs(c+f+g-3)<o)return this.set(1,0,0,0),this;t=Math.PI;let e=(c+1)/2,s=(f+1)/2,_=(g+1)/2,v=(l+d)/4,y=(u+m)/4,b=(p+h)/4;return e>s&&e>_?e<a?(n=0,r=.707106781,i=.707106781):(n=Math.sqrt(e),r=v/n,i=y/n):s>_?s<a?(n=.707106781,r=0,i=.707106781):(r=Math.sqrt(s),n=v/r,i=b/r):_<a?(n=.707106781,r=.707106781,i=0):(i=Math.sqrt(_),n=y/i,r=b/i),this.set(n,r,i,t),this}let _=Math.sqrt((h-p)*(h-p)+(u-m)*(u-m)+(d-l)*(d-l));return Math.abs(_)<.001&&(_=1),this.x=(h-p)/_,this.y=(u-m)/_,this.z=(d-l)/_,this.w=Math.acos((c+f+g-1)/2),this}setFromMatrixPosition(e){let t=e.elements;return this.x=t[12],this.y=t[13],this.z=t[14],this.w=t[15],this}min(e){return this.x=Math.min(this.x,e.x),this.y=Math.min(this.y,e.y),this.z=Math.min(this.z,e.z),this.w=Math.min(this.w,e.w),this}max(e){return this.x=Math.max(this.x,e.x),this.y=Math.max(this.y,e.y),this.z=Math.max(this.z,e.z),this.w=Math.max(this.w,e.w),this}clamp(e,t){return this.x=Math.max(e.x,Math.min(t.x,this.x)),this.y=Math.max(e.y,Math.min(t.y,this.y)),this.z=Math.max(e.z,Math.min(t.z,this.z)),this.w=Math.max(e.w,Math.min(t.w,this.w)),this}clampScalar(e,t){return this.x=Math.max(e,Math.min(t,this.x)),this.y=Math.max(e,Math.min(t,this.y)),this.z=Math.max(e,Math.min(t,this.z)),this.w=Math.max(e,Math.min(t,this.w)),this}clampLength(e,t){let n=this.length();return this.divideScalar(n||1).multiplyScalar(Math.max(e,Math.min(t,n)))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this.z=Math.floor(this.z),this.w=Math.floor(this.w),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this.z=Math.ceil(this.z),this.w=Math.ceil(this.w),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this.z=Math.round(this.z),this.w=Math.round(this.w),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this.z=Math.trunc(this.z),this.w=Math.trunc(this.w),this}negate(){return this.x=-this.x,this.y=-this.y,this.z=-this.z,this.w=-this.w,this}dot(e){return this.x*e.x+this.y*e.y+this.z*e.z+this.w*e.w}lengthSq(){return this.x*this.x+this.y*this.y+this.z*this.z+this.w*this.w}length(){return Math.sqrt(this.x*this.x+this.y*this.y+this.z*this.z+this.w*this.w)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)+Math.abs(this.z)+Math.abs(this.w)}normalize(){return this.divideScalar(this.length()||1)}setLength(e){return this.normalize().multiplyScalar(e)}lerp(e,t){return this.x+=(e.x-this.x)*t,this.y+=(e.y-this.y)*t,this.z+=(e.z-this.z)*t,this.w+=(e.w-this.w)*t,this}lerpVectors(e,t,n){return this.x=e.x+(t.x-e.x)*n,this.y=e.y+(t.y-e.y)*n,this.z=e.z+(t.z-e.z)*n,this.w=e.w+(t.w-e.w)*n,this}equals(e){return e.x===this.x&&e.y===this.y&&e.z===this.z&&e.w===this.w}fromArray(e,t=0){return this.x=e[t],this.y=e[t+1],this.z=e[t+2],this.w=e[t+3],this}toArray(e=[],t=0){return e[t]=this.x,e[t+1]=this.y,e[t+2]=this.z,e[t+3]=this.w,e}fromBufferAttribute(e,t){return this.x=e.getX(t),this.y=e.getY(t),this.z=e.getZ(t),this.w=e.getW(t),this}random(){return this.x=Math.random(),this.y=Math.random(),this.z=Math.random(),this.w=Math.random(),this}*[Symbol.iterator](){yield this.x,yield this.y,yield this.z,yield this.w}},Ut=class extends Ge{constructor(e=1,t=1,n={}){super(),this.isRenderTarget=!0,this.width=e,this.height=t,this.depth=1,this.scissor=new B(0,0,e,t),this.scissorTest=!1,this.viewport=new B(0,0,e,t);let r={width:e,height:t,depth:1};n=Object.assign({generateMipmaps:!1,internalFormat:null,minFilter:l,depthBuffer:!0,stencilBuffer:!1,resolveDepthBuffer:!0,resolveStencilBuffer:!0,depthTexture:null,samples:0,count:1},n);let i=new Ht(r,n.mapping,n.wrapS,n.wrapT,n.magFilter,n.minFilter,n.format,n.type,n.anisotropy,n.colorSpace);i.flipY=!1,i.generateMipmaps=n.generateMipmaps,i.internalFormat=n.internalFormat,this.textures=[];let a=n.count;for(let e=0;e<a;e++)this.textures[e]=i.clone(),this.textures[e].isRenderTargetTexture=!0;this.depthBuffer=n.depthBuffer,this.stencilBuffer=n.stencilBuffer,this.resolveDepthBuffer=n.resolveDepthBuffer,this.resolveStencilBuffer=n.resolveStencilBuffer,this.depthTexture=n.depthTexture,this.samples=n.samples}get texture(){return this.textures[0]}set texture(e){this.textures[0]=e}setSize(e,t,n=1){if(this.width!==e||this.height!==t||this.depth!==n){this.width=e,this.height=t,this.depth=n;for(let r=0,i=this.textures.length;r<i;r++)this.textures[r].image.width=e,this.textures[r].image.height=t,this.textures[r].image.depth=n;this.dispose()}this.viewport.set(0,0,e,t),this.scissor.set(0,0,e,t)}clone(){return new this.constructor().copy(this)}copy(e){this.width=e.width,this.height=e.height,this.depth=e.depth,this.scissor.copy(e.scissor),this.scissorTest=e.scissorTest,this.viewport.copy(e.viewport),this.textures.length=0;for(let t=0,n=e.textures.length;t<n;t++)this.textures[t]=e.textures[t].clone(),this.textures[t].isRenderTargetTexture=!0;let t=Object.assign({},e.texture.image);return this.texture.source=new zt(t),this.depthBuffer=e.depthBuffer,this.stencilBuffer=e.stencilBuffer,this.resolveDepthBuffer=e.resolveDepthBuffer,this.resolveStencilBuffer=e.resolveStencilBuffer,e.depthTexture!==null&&(this.depthTexture=e.depthTexture.clone()),this.samples=e.samples,this}dispose(){this.dispatchEvent({type:`dispose`})}},Wt=class extends Ut{constructor(e=1,t=1,n={}){super(e,t,n),this.isWebGLRenderTarget=!0}},Gt=class extends Ht{constructor(e=null,t=1,n=1,r=1){super(null),this.isDataArrayTexture=!0,this.image={data:e,width:t,height:n,depth:r},this.magFilter=o,this.minFilter=o,this.wrapR=i,this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1,this.layerUpdates=new Set}addLayerUpdate(e){this.layerUpdates.add(e)}clearLayerUpdates(){this.layerUpdates.clear()}},Kt=class extends Ht{constructor(e=null,t=1,n=1,r=1){super(null),this.isData3DTexture=!0,this.image={data:e,width:t,height:n,depth:r},this.magFilter=o,this.minFilter=o,this.wrapR=i,this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1}},V=class{constructor(e=0,t=0,n=0,r=1){this.isQuaternion=!0,this._x=e,this._y=t,this._z=n,this._w=r}static slerpFlat(e,t,n,r,i,a,o){let s=n[r+0],c=n[r+1],l=n[r+2],u=n[r+3],d=i[a+0],f=i[a+1],p=i[a+2],m=i[a+3];if(o===0){e[t+0]=s,e[t+1]=c,e[t+2]=l,e[t+3]=u;return}if(o===1){e[t+0]=d,e[t+1]=f,e[t+2]=p,e[t+3]=m;return}if(u!==m||s!==d||c!==f||l!==p){let e=1-o,t=s*d+c*f+l*p+u*m,n=t>=0?1:-1,r=1-t*t;if(r>2**-52){let i=Math.sqrt(r),a=Math.atan2(i,t*n);e=Math.sin(e*a)/i,o=Math.sin(o*a)/i}let i=o*n;if(s=s*e+d*i,c=c*e+f*i,l=l*e+p*i,u=u*e+m*i,e===1-o){let e=1/Math.sqrt(s*s+c*c+l*l+u*u);s*=e,c*=e,l*=e,u*=e}}e[t]=s,e[t+1]=c,e[t+2]=l,e[t+3]=u}static multiplyQuaternionsFlat(e,t,n,r,i,a){let o=n[r],s=n[r+1],c=n[r+2],l=n[r+3],u=i[a],d=i[a+1],f=i[a+2],p=i[a+3];return e[t]=o*p+l*u+s*f-c*d,e[t+1]=s*p+l*d+c*u-o*f,e[t+2]=c*p+l*f+o*d-s*u,e[t+3]=l*p-o*u-s*d-c*f,e}get x(){return this._x}set x(e){this._x=e,this._onChangeCallback()}get y(){return this._y}set y(e){this._y=e,this._onChangeCallback()}get z(){return this._z}set z(e){this._z=e,this._onChangeCallback()}get w(){return this._w}set w(e){this._w=e,this._onChangeCallback()}set(e,t,n,r){return this._x=e,this._y=t,this._z=n,this._w=r,this._onChangeCallback(),this}clone(){return new this.constructor(this._x,this._y,this._z,this._w)}copy(e){return this._x=e.x,this._y=e.y,this._z=e.z,this._w=e.w,this._onChangeCallback(),this}setFromEuler(e,t=!0){let n=e._x,r=e._y,i=e._z,a=e._order,o=Math.cos,s=Math.sin,c=o(n/2),l=o(r/2),u=o(i/2),d=s(n/2),f=s(r/2),p=s(i/2);switch(a){case`XYZ`:this._x=d*l*u+c*f*p,this._y=c*f*u-d*l*p,this._z=c*l*p+d*f*u,this._w=c*l*u-d*f*p;break;case`YXZ`:this._x=d*l*u+c*f*p,this._y=c*f*u-d*l*p,this._z=c*l*p-d*f*u,this._w=c*l*u+d*f*p;break;case`ZXY`:this._x=d*l*u-c*f*p,this._y=c*f*u+d*l*p,this._z=c*l*p+d*f*u,this._w=c*l*u-d*f*p;break;case`ZYX`:this._x=d*l*u-c*f*p,this._y=c*f*u+d*l*p,this._z=c*l*p-d*f*u,this._w=c*l*u+d*f*p;break;case`YZX`:this._x=d*l*u+c*f*p,this._y=c*f*u+d*l*p,this._z=c*l*p-d*f*u,this._w=c*l*u-d*f*p;break;case`XZY`:this._x=d*l*u-c*f*p,this._y=c*f*u-d*l*p,this._z=c*l*p+d*f*u,this._w=c*l*u+d*f*p;break;default:console.warn(`THREE.Quaternion: .setFromEuler() encountered an unknown order: `+a)}return t===!0&&this._onChangeCallback(),this}setFromAxisAngle(e,t){let n=t/2,r=Math.sin(n);return this._x=e.x*r,this._y=e.y*r,this._z=e.z*r,this._w=Math.cos(n),this._onChangeCallback(),this}setFromRotationMatrix(e){let t=e.elements,n=t[0],r=t[4],i=t[8],a=t[1],o=t[5],s=t[9],c=t[2],l=t[6],u=t[10],d=n+o+u;if(d>0){let e=.5/Math.sqrt(d+1);this._w=.25/e,this._x=(l-s)*e,this._y=(i-c)*e,this._z=(a-r)*e}else if(n>o&&n>u){let e=2*Math.sqrt(1+n-o-u);this._w=(l-s)/e,this._x=.25*e,this._y=(r+a)/e,this._z=(i+c)/e}else if(o>u){let e=2*Math.sqrt(1+o-n-u);this._w=(i-c)/e,this._x=(r+a)/e,this._y=.25*e,this._z=(s+l)/e}else{let e=2*Math.sqrt(1+u-n-o);this._w=(a-r)/e,this._x=(i+c)/e,this._y=(s+l)/e,this._z=.25*e}return this._onChangeCallback(),this}setFromUnitVectors(e,t){let n=e.dot(t)+1;return n<2**-52?(n=0,Math.abs(e.x)>Math.abs(e.z)?(this._x=-e.y,this._y=e.x,this._z=0,this._w=n):(this._x=0,this._y=-e.z,this._z=e.y,this._w=n)):(this._x=e.y*t.z-e.z*t.y,this._y=e.z*t.x-e.x*t.z,this._z=e.x*t.y-e.y*t.x,this._w=n),this.normalize()}angleTo(e){return 2*Math.acos(Math.abs(Ze(this.dot(e),-1,1)))}rotateTowards(e,t){let n=this.angleTo(e);if(n===0)return this;let r=Math.min(1,t/n);return this.slerp(e,r),this}identity(){return this.set(0,0,0,1)}invert(){return this.conjugate()}conjugate(){return this._x*=-1,this._y*=-1,this._z*=-1,this._onChangeCallback(),this}dot(e){return this._x*e._x+this._y*e._y+this._z*e._z+this._w*e._w}lengthSq(){return this._x*this._x+this._y*this._y+this._z*this._z+this._w*this._w}length(){return Math.sqrt(this._x*this._x+this._y*this._y+this._z*this._z+this._w*this._w)}normalize(){let e=this.length();return e===0?(this._x=0,this._y=0,this._z=0,this._w=1):(e=1/e,this._x*=e,this._y*=e,this._z*=e,this._w*=e),this._onChangeCallback(),this}multiply(e){return this.multiplyQuaternions(this,e)}premultiply(e){return this.multiplyQuaternions(e,this)}multiplyQuaternions(e,t){let n=e._x,r=e._y,i=e._z,a=e._w,o=t._x,s=t._y,c=t._z,l=t._w;return this._x=n*l+a*o+r*c-i*s,this._y=r*l+a*s+i*o-n*c,this._z=i*l+a*c+n*s-r*o,this._w=a*l-n*o-r*s-i*c,this._onChangeCallback(),this}slerp(e,t){if(t===0)return this;if(t===1)return this.copy(e);let n=this._x,r=this._y,i=this._z,a=this._w,o=a*e._w+n*e._x+r*e._y+i*e._z;if(o<0?(this._w=-e._w,this._x=-e._x,this._y=-e._y,this._z=-e._z,o=-o):this.copy(e),o>=1)return this._w=a,this._x=n,this._y=r,this._z=i,this;let s=1-o*o;if(s<=2**-52){let e=1-t;return this._w=e*a+t*this._w,this._x=e*n+t*this._x,this._y=e*r+t*this._y,this._z=e*i+t*this._z,this.normalize(),this}let c=Math.sqrt(s),l=Math.atan2(c,o),u=Math.sin((1-t)*l)/c,d=Math.sin(t*l)/c;return this._w=a*u+this._w*d,this._x=n*u+this._x*d,this._y=r*u+this._y*d,this._z=i*u+this._z*d,this._onChangeCallback(),this}slerpQuaternions(e,t,n){return this.copy(e).slerp(t,n)}random(){let e=2*Math.PI*Math.random(),t=2*Math.PI*Math.random(),n=Math.random(),r=Math.sqrt(1-n),i=Math.sqrt(n);return this.set(r*Math.sin(e),r*Math.cos(e),i*Math.sin(t),i*Math.cos(t))}equals(e){return e._x===this._x&&e._y===this._y&&e._z===this._z&&e._w===this._w}fromArray(e,t=0){return this._x=e[t],this._y=e[t+1],this._z=e[t+2],this._w=e[t+3],this._onChangeCallback(),this}toArray(e=[],t=0){return e[t]=this._x,e[t+1]=this._y,e[t+2]=this._z,e[t+3]=this._w,e}fromBufferAttribute(e,t){return this._x=e.getX(t),this._y=e.getY(t),this._z=e.getZ(t),this._w=e.getW(t),this._onChangeCallback(),this}toJSON(){return this.toArray()}_onChange(e){return this._onChangeCallback=e,this}_onChangeCallback(){}*[Symbol.iterator](){yield this._x,yield this._y,yield this._z,yield this._w}},H=class e{constructor(t=0,n=0,r=0){e.prototype.isVector3=!0,this.x=t,this.y=n,this.z=r}set(e,t,n){return n===void 0&&(n=this.z),this.x=e,this.y=t,this.z=n,this}setScalar(e){return this.x=e,this.y=e,this.z=e,this}setX(e){return this.x=e,this}setY(e){return this.y=e,this}setZ(e){return this.z=e,this}setComponent(e,t){switch(e){case 0:this.x=t;break;case 1:this.y=t;break;case 2:this.z=t;break;default:throw Error(`index is out of range: `+e)}return this}getComponent(e){switch(e){case 0:return this.x;case 1:return this.y;case 2:return this.z;default:throw Error(`index is out of range: `+e)}}clone(){return new this.constructor(this.x,this.y,this.z)}copy(e){return this.x=e.x,this.y=e.y,this.z=e.z,this}add(e){return this.x+=e.x,this.y+=e.y,this.z+=e.z,this}addScalar(e){return this.x+=e,this.y+=e,this.z+=e,this}addVectors(e,t){return this.x=e.x+t.x,this.y=e.y+t.y,this.z=e.z+t.z,this}addScaledVector(e,t){return this.x+=e.x*t,this.y+=e.y*t,this.z+=e.z*t,this}sub(e){return this.x-=e.x,this.y-=e.y,this.z-=e.z,this}subScalar(e){return this.x-=e,this.y-=e,this.z-=e,this}subVectors(e,t){return this.x=e.x-t.x,this.y=e.y-t.y,this.z=e.z-t.z,this}multiply(e){return this.x*=e.x,this.y*=e.y,this.z*=e.z,this}multiplyScalar(e){return this.x*=e,this.y*=e,this.z*=e,this}multiplyVectors(e,t){return this.x=e.x*t.x,this.y=e.y*t.y,this.z=e.z*t.z,this}applyEuler(e){return this.applyQuaternion(Jt.setFromEuler(e))}applyAxisAngle(e,t){return this.applyQuaternion(Jt.setFromAxisAngle(e,t))}applyMatrix3(e){let t=this.x,n=this.y,r=this.z,i=e.elements;return this.x=i[0]*t+i[3]*n+i[6]*r,this.y=i[1]*t+i[4]*n+i[7]*r,this.z=i[2]*t+i[5]*n+i[8]*r,this}applyNormalMatrix(e){return this.applyMatrix3(e).normalize()}applyMatrix4(e){let t=this.x,n=this.y,r=this.z,i=e.elements,a=1/(i[3]*t+i[7]*n+i[11]*r+i[15]);return this.x=(i[0]*t+i[4]*n+i[8]*r+i[12])*a,this.y=(i[1]*t+i[5]*n+i[9]*r+i[13])*a,this.z=(i[2]*t+i[6]*n+i[10]*r+i[14])*a,this}applyQuaternion(e){let t=this.x,n=this.y,r=this.z,i=e.x,a=e.y,o=e.z,s=e.w,c=2*(a*r-o*n),l=2*(o*t-i*r),u=2*(i*n-a*t);return this.x=t+s*c+a*u-o*l,this.y=n+s*l+o*c-i*u,this.z=r+s*u+i*l-a*c,this}project(e){return this.applyMatrix4(e.matrixWorldInverse).applyMatrix4(e.projectionMatrix)}unproject(e){return this.applyMatrix4(e.projectionMatrixInverse).applyMatrix4(e.matrixWorld)}transformDirection(e){let t=this.x,n=this.y,r=this.z,i=e.elements;return this.x=i[0]*t+i[4]*n+i[8]*r,this.y=i[1]*t+i[5]*n+i[9]*r,this.z=i[2]*t+i[6]*n+i[10]*r,this.normalize()}divide(e){return this.x/=e.x,this.y/=e.y,this.z/=e.z,this}divideScalar(e){return this.multiplyScalar(1/e)}min(e){return this.x=Math.min(this.x,e.x),this.y=Math.min(this.y,e.y),this.z=Math.min(this.z,e.z),this}max(e){return this.x=Math.max(this.x,e.x),this.y=Math.max(this.y,e.y),this.z=Math.max(this.z,e.z),this}clamp(e,t){return this.x=Math.max(e.x,Math.min(t.x,this.x)),this.y=Math.max(e.y,Math.min(t.y,this.y)),this.z=Math.max(e.z,Math.min(t.z,this.z)),this}clampScalar(e,t){return this.x=Math.max(e,Math.min(t,this.x)),this.y=Math.max(e,Math.min(t,this.y)),this.z=Math.max(e,Math.min(t,this.z)),this}clampLength(e,t){let n=this.length();return this.divideScalar(n||1).multiplyScalar(Math.max(e,Math.min(t,n)))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this.z=Math.floor(this.z),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this.z=Math.ceil(this.z),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this.z=Math.round(this.z),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this.z=Math.trunc(this.z),this}negate(){return this.x=-this.x,this.y=-this.y,this.z=-this.z,this}dot(e){return this.x*e.x+this.y*e.y+this.z*e.z}lengthSq(){return this.x*this.x+this.y*this.y+this.z*this.z}length(){return Math.sqrt(this.x*this.x+this.y*this.y+this.z*this.z)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)+Math.abs(this.z)}normalize(){return this.divideScalar(this.length()||1)}setLength(e){return this.normalize().multiplyScalar(e)}lerp(e,t){return this.x+=(e.x-this.x)*t,this.y+=(e.y-this.y)*t,this.z+=(e.z-this.z)*t,this}lerpVectors(e,t,n){return this.x=e.x+(t.x-e.x)*n,this.y=e.y+(t.y-e.y)*n,this.z=e.z+(t.z-e.z)*n,this}cross(e){return this.crossVectors(this,e)}crossVectors(e,t){let n=e.x,r=e.y,i=e.z,a=t.x,o=t.y,s=t.z;return this.x=r*s-i*o,this.y=i*a-n*s,this.z=n*o-r*a,this}projectOnVector(e){let t=e.lengthSq();if(t===0)return this.set(0,0,0);let n=e.dot(this)/t;return this.copy(e).multiplyScalar(n)}projectOnPlane(e){return qt.copy(this).projectOnVector(e),this.sub(qt)}reflect(e){return this.sub(qt.copy(e).multiplyScalar(2*this.dot(e)))}angleTo(e){let t=Math.sqrt(this.lengthSq()*e.lengthSq());if(t===0)return Math.PI/2;let n=this.dot(e)/t;return Math.acos(Ze(n,-1,1))}distanceTo(e){return Math.sqrt(this.distanceToSquared(e))}distanceToSquared(e){let t=this.x-e.x,n=this.y-e.y,r=this.z-e.z;return t*t+n*n+r*r}manhattanDistanceTo(e){return Math.abs(this.x-e.x)+Math.abs(this.y-e.y)+Math.abs(this.z-e.z)}setFromSpherical(e){return this.setFromSphericalCoords(e.radius,e.phi,e.theta)}setFromSphericalCoords(e,t,n){let r=Math.sin(t)*e;return this.x=r*Math.sin(n),this.y=Math.cos(t)*e,this.z=r*Math.cos(n),this}setFromCylindrical(e){return this.setFromCylindricalCoords(e.radius,e.theta,e.y)}setFromCylindricalCoords(e,t,n){return this.x=e*Math.sin(t),this.y=n,this.z=e*Math.cos(t),this}setFromMatrixPosition(e){let t=e.elements;return this.x=t[12],this.y=t[13],this.z=t[14],this}setFromMatrixScale(e){let t=this.setFromMatrixColumn(e,0).length(),n=this.setFromMatrixColumn(e,1).length(),r=this.setFromMatrixColumn(e,2).length();return this.x=t,this.y=n,this.z=r,this}setFromMatrixColumn(e,t){return this.fromArray(e.elements,t*4)}setFromMatrix3Column(e,t){return this.fromArray(e.elements,t*3)}setFromEuler(e){return this.x=e._x,this.y=e._y,this.z=e._z,this}setFromColor(e){return this.x=e.r,this.y=e.g,this.z=e.b,this}equals(e){return e.x===this.x&&e.y===this.y&&e.z===this.z}fromArray(e,t=0){return this.x=e[t],this.y=e[t+1],this.z=e[t+2],this}toArray(e=[],t=0){return e[t]=this.x,e[t+1]=this.y,e[t+2]=this.z,e}fromBufferAttribute(e,t){return this.x=e.getX(t),this.y=e.getY(t),this.z=e.getZ(t),this}random(){return this.x=Math.random(),this.y=Math.random(),this.z=Math.random(),this}randomDirection(){let e=Math.random()*Math.PI*2,t=Math.random()*2-1,n=Math.sqrt(1-t*t);return this.x=n*Math.cos(e),this.y=t,this.z=n*Math.sin(e),this}*[Symbol.iterator](){yield this.x,yield this.y,yield this.z}},qt=new H,Jt=new V,Yt=class{constructor(e=new H(1/0,1/0,1/0),t=new H(-1/0,-1/0,-1/0)){this.isBox3=!0,this.min=e,this.max=t}set(e,t){return this.min.copy(e),this.max.copy(t),this}setFromArray(e){this.makeEmpty();for(let t=0,n=e.length;t<n;t+=3)this.expandByPoint(Zt.fromArray(e,t));return this}setFromBufferAttribute(e){this.makeEmpty();for(let t=0,n=e.count;t<n;t++)this.expandByPoint(Zt.fromBufferAttribute(e,t));return this}setFromPoints(e){this.makeEmpty();for(let t=0,n=e.length;t<n;t++)this.expandByPoint(e[t]);return this}setFromCenterAndSize(e,t){let n=Zt.copy(t).multiplyScalar(.5);return this.min.copy(e).sub(n),this.max.copy(e).add(n),this}setFromObject(e,t=!1){return this.makeEmpty(),this.expandByObject(e,t)}clone(){return new this.constructor().copy(this)}copy(e){return this.min.copy(e.min),this.max.copy(e.max),this}makeEmpty(){return this.min.x=this.min.y=this.min.z=1/0,this.max.x=this.max.y=this.max.z=-1/0,this}isEmpty(){return this.max.x<this.min.x||this.max.y<this.min.y||this.max.z<this.min.z}getCenter(e){return this.isEmpty()?e.set(0,0,0):e.addVectors(this.min,this.max).multiplyScalar(.5)}getSize(e){return this.isEmpty()?e.set(0,0,0):e.subVectors(this.max,this.min)}expandByPoint(e){return this.min.min(e),this.max.max(e),this}expandByVector(e){return this.min.sub(e),this.max.add(e),this}expandByScalar(e){return this.min.addScalar(-e),this.max.addScalar(e),this}expandByObject(e,t=!1){e.updateWorldMatrix(!1,!1);let n=e.geometry;if(n!==void 0){let r=n.getAttribute(`position`);if(t===!0&&r!==void 0&&e.isInstancedMesh!==!0)for(let t=0,n=r.count;t<n;t++)e.isMesh===!0?e.getVertexPosition(t,Zt):Zt.fromBufferAttribute(r,t),Zt.applyMatrix4(e.matrixWorld),this.expandByPoint(Zt);else e.boundingBox===void 0?(n.boundingBox===null&&n.computeBoundingBox(),Qt.copy(n.boundingBox)):(e.boundingBox===null&&e.computeBoundingBox(),Qt.copy(e.boundingBox)),Qt.applyMatrix4(e.matrixWorld),this.union(Qt)}let r=e.children;for(let e=0,n=r.length;e<n;e++)this.expandByObject(r[e],t);return this}containsPoint(e){return e.x>=this.min.x&&e.x<=this.max.x&&e.y>=this.min.y&&e.y<=this.max.y&&e.z>=this.min.z&&e.z<=this.max.z}containsBox(e){return this.min.x<=e.min.x&&e.max.x<=this.max.x&&this.min.y<=e.min.y&&e.max.y<=this.max.y&&this.min.z<=e.min.z&&e.max.z<=this.max.z}getParameter(e,t){return t.set((e.x-this.min.x)/(this.max.x-this.min.x),(e.y-this.min.y)/(this.max.y-this.min.y),(e.z-this.min.z)/(this.max.z-this.min.z))}intersectsBox(e){return e.max.x>=this.min.x&&e.min.x<=this.max.x&&e.max.y>=this.min.y&&e.min.y<=this.max.y&&e.max.z>=this.min.z&&e.min.z<=this.max.z}intersectsSphere(e){return this.clampPoint(e.center,Zt),Zt.distanceToSquared(e.center)<=e.radius*e.radius}intersectsPlane(e){let t,n;return e.normal.x>0?(t=e.normal.x*this.min.x,n=e.normal.x*this.max.x):(t=e.normal.x*this.max.x,n=e.normal.x*this.min.x),e.normal.y>0?(t+=e.normal.y*this.min.y,n+=e.normal.y*this.max.y):(t+=e.normal.y*this.max.y,n+=e.normal.y*this.min.y),e.normal.z>0?(t+=e.normal.z*this.min.z,n+=e.normal.z*this.max.z):(t+=e.normal.z*this.max.z,n+=e.normal.z*this.min.z),t<=-e.constant&&n>=-e.constant}intersectsTriangle(e){if(this.isEmpty())return!1;this.getCenter(on),sn.subVectors(this.max,on),$t.subVectors(e.a,on),en.subVectors(e.b,on),tn.subVectors(e.c,on),nn.subVectors(en,$t),rn.subVectors(tn,en),an.subVectors($t,tn);let t=[0,-nn.z,nn.y,0,-rn.z,rn.y,0,-an.z,an.y,nn.z,0,-nn.x,rn.z,0,-rn.x,an.z,0,-an.x,-nn.y,nn.x,0,-rn.y,rn.x,0,-an.y,an.x,0];return!un(t,$t,en,tn,sn)||(t=[1,0,0,0,1,0,0,0,1],!un(t,$t,en,tn,sn))?!1:(cn.crossVectors(nn,rn),t=[cn.x,cn.y,cn.z],un(t,$t,en,tn,sn))}clampPoint(e,t){return t.copy(e).clamp(this.min,this.max)}distanceToPoint(e){return this.clampPoint(e,Zt).distanceTo(e)}getBoundingSphere(e){return this.isEmpty()?e.makeEmpty():(this.getCenter(e.center),e.radius=this.getSize(Zt).length()*.5),e}intersect(e){return this.min.max(e.min),this.max.min(e.max),this.isEmpty()&&this.makeEmpty(),this}union(e){return this.min.min(e.min),this.max.max(e.max),this}applyMatrix4(e){return this.isEmpty()?this:(Xt[0].set(this.min.x,this.min.y,this.min.z).applyMatrix4(e),Xt[1].set(this.min.x,this.min.y,this.max.z).applyMatrix4(e),Xt[2].set(this.min.x,this.max.y,this.min.z).applyMatrix4(e),Xt[3].set(this.min.x,this.max.y,this.max.z).applyMatrix4(e),Xt[4].set(this.max.x,this.min.y,this.min.z).applyMatrix4(e),Xt[5].set(this.max.x,this.min.y,this.max.z).applyMatrix4(e),Xt[6].set(this.max.x,this.max.y,this.min.z).applyMatrix4(e),Xt[7].set(this.max.x,this.max.y,this.max.z).applyMatrix4(e),this.setFromPoints(Xt),this)}translate(e){return this.min.add(e),this.max.add(e),this}equals(e){return e.min.equals(this.min)&&e.max.equals(this.max)}},Xt=[new H,new H,new H,new H,new H,new H,new H,new H],Zt=new H,Qt=new Yt,$t=new H,en=new H,tn=new H,nn=new H,rn=new H,an=new H,on=new H,sn=new H,cn=new H,ln=new H;function un(e,t,n,r,i){for(let a=0,o=e.length-3;a<=o;a+=3){ln.fromArray(e,a);let o=i.x*Math.abs(ln.x)+i.y*Math.abs(ln.y)+i.z*Math.abs(ln.z),s=t.dot(ln),c=n.dot(ln),l=r.dot(ln);if(Math.max(-Math.max(s,c,l),Math.min(s,c,l))>o)return!1}return!0}var dn=new Yt,fn=new H,pn=new H,mn=class{constructor(e=new H,t=-1){this.isSphere=!0,this.center=e,this.radius=t}set(e,t){return this.center.copy(e),this.radius=t,this}setFromPoints(e,t){let n=this.center;t===void 0?dn.setFromPoints(e).getCenter(n):n.copy(t);let r=0;for(let t=0,i=e.length;t<i;t++)r=Math.max(r,n.distanceToSquared(e[t]));return this.radius=Math.sqrt(r),this}copy(e){return this.center.copy(e.center),this.radius=e.radius,this}isEmpty(){return this.radius<0}makeEmpty(){return this.center.set(0,0,0),this.radius=-1,this}containsPoint(e){return e.distanceToSquared(this.center)<=this.radius*this.radius}distanceToPoint(e){return e.distanceTo(this.center)-this.radius}intersectsSphere(e){let t=this.radius+e.radius;return e.center.distanceToSquared(this.center)<=t*t}intersectsBox(e){return e.intersectsSphere(this)}intersectsPlane(e){return Math.abs(e.distanceToPoint(this.center))<=this.radius}clampPoint(e,t){let n=this.center.distanceToSquared(e);return t.copy(e),n>this.radius*this.radius&&(t.sub(this.center).normalize(),t.multiplyScalar(this.radius).add(this.center)),t}getBoundingBox(e){return this.isEmpty()?(e.makeEmpty(),e):(e.set(this.center,this.center),e.expandByScalar(this.radius),e)}applyMatrix4(e){return this.center.applyMatrix4(e),this.radius*=e.getMaxScaleOnAxis(),this}translate(e){return this.center.add(e),this}expandByPoint(e){if(this.isEmpty())return this.center.copy(e),this.radius=0,this;fn.subVectors(e,this.center);let t=fn.lengthSq();if(t>this.radius*this.radius){let e=Math.sqrt(t),n=(e-this.radius)*.5;this.center.addScaledVector(fn,n/e),this.radius+=n}return this}union(e){return e.isEmpty()?this:this.isEmpty()?(this.copy(e),this):(this.center.equals(e.center)===!0?this.radius=Math.max(this.radius,e.radius):(pn.subVectors(e.center,this.center).setLength(e.radius),this.expandByPoint(fn.copy(e.center).add(pn)),this.expandByPoint(fn.copy(e.center).sub(pn))),this)}equals(e){return e.center.equals(this.center)&&e.radius===this.radius}clone(){return new this.constructor().copy(this)}},hn=new H,gn=new H,_n=new H,vn=new H,yn=new H,bn=new H,xn=new H,Sn=class{constructor(e=new H,t=new H(0,0,-1)){this.origin=e,this.direction=t}set(e,t){return this.origin.copy(e),this.direction.copy(t),this}copy(e){return this.origin.copy(e.origin),this.direction.copy(e.direction),this}at(e,t){return t.copy(this.origin).addScaledVector(this.direction,e)}lookAt(e){return this.direction.copy(e).sub(this.origin).normalize(),this}recast(e){return this.origin.copy(this.at(e,hn)),this}closestPointToPoint(e,t){t.subVectors(e,this.origin);let n=t.dot(this.direction);return n<0?t.copy(this.origin):t.copy(this.origin).addScaledVector(this.direction,n)}distanceToPoint(e){return Math.sqrt(this.distanceSqToPoint(e))}distanceSqToPoint(e){let t=hn.subVectors(e,this.origin).dot(this.direction);return t<0?this.origin.distanceToSquared(e):(hn.copy(this.origin).addScaledVector(this.direction,t),hn.distanceToSquared(e))}distanceSqToSegment(e,t,n,r){gn.copy(e).add(t).multiplyScalar(.5),_n.copy(t).sub(e).normalize(),vn.copy(this.origin).sub(gn);let i=e.distanceTo(t)*.5,a=-this.direction.dot(_n),o=vn.dot(this.direction),s=-vn.dot(_n),c=vn.lengthSq(),l=Math.abs(1-a*a),u,d,f,p;if(l>0){if(u=a*s-o,d=a*o-s,p=i*l,u>=0){if(d>=-p){if(d<=p){let e=1/l;u*=e,d*=e,f=u*(u+a*d+2*o)+d*(a*u+d+2*s)+c}else d=i,u=Math.max(0,-(a*d+o)),f=-u*u+d*(d+2*s)+c}else d=-i,u=Math.max(0,-(a*d+o)),f=-u*u+d*(d+2*s)+c}else d<=-p?(u=Math.max(0,-(-a*i+o)),d=u>0?-i:Math.min(Math.max(-i,-s),i),f=-u*u+d*(d+2*s)+c):d<=p?(u=0,d=Math.min(Math.max(-i,-s),i),f=d*(d+2*s)+c):(u=Math.max(0,-(a*i+o)),d=u>0?i:Math.min(Math.max(-i,-s),i),f=-u*u+d*(d+2*s)+c)}else d=a>0?-i:i,u=Math.max(0,-(a*d+o)),f=-u*u+d*(d+2*s)+c;return n&&n.copy(this.origin).addScaledVector(this.direction,u),r&&r.copy(gn).addScaledVector(_n,d),f}intersectSphere(e,t){hn.subVectors(e.center,this.origin);let n=hn.dot(this.direction),r=hn.dot(hn)-n*n,i=e.radius*e.radius;if(r>i)return null;let a=Math.sqrt(i-r),o=n-a,s=n+a;return s<0?null:o<0?this.at(s,t):this.at(o,t)}intersectsSphere(e){return this.distanceSqToPoint(e.center)<=e.radius*e.radius}distanceToPlane(e){let t=e.normal.dot(this.direction);if(t===0)return e.distanceToPoint(this.origin)===0?0:null;let n=-(this.origin.dot(e.normal)+e.constant)/t;return n>=0?n:null}intersectPlane(e,t){let n=this.distanceToPlane(e);return n===null?null:this.at(n,t)}intersectsPlane(e){let t=e.distanceToPoint(this.origin);return t===0||e.normal.dot(this.direction)*t<0}intersectBox(e,t){let n,r,i,a,o,s,c=1/this.direction.x,l=1/this.direction.y,u=1/this.direction.z,d=this.origin;return c>=0?(n=(e.min.x-d.x)*c,r=(e.max.x-d.x)*c):(n=(e.max.x-d.x)*c,r=(e.min.x-d.x)*c),l>=0?(i=(e.min.y-d.y)*l,a=(e.max.y-d.y)*l):(i=(e.max.y-d.y)*l,a=(e.min.y-d.y)*l),n>a||i>r||((i>n||isNaN(n))&&(n=i),(a<r||isNaN(r))&&(r=a),u>=0?(o=(e.min.z-d.z)*u,s=(e.max.z-d.z)*u):(o=(e.max.z-d.z)*u,s=(e.min.z-d.z)*u),n>s||o>r)||((o>n||n!==n)&&(n=o),(s<r||r!==r)&&(r=s),r<0)?null:this.at(n>=0?n:r,t)}intersectsBox(e){return this.intersectBox(e,hn)!==null}intersectTriangle(e,t,n,r,i){yn.subVectors(t,e),bn.subVectors(n,e),xn.crossVectors(yn,bn);let a=this.direction.dot(xn),o;if(a>0){if(r)return null;o=1}else if(a<0)o=-1,a=-a;else return null;vn.subVectors(this.origin,e);let s=o*this.direction.dot(bn.crossVectors(vn,bn));if(s<0)return null;let c=o*this.direction.dot(yn.cross(vn));if(c<0||s+c>a)return null;let l=-o*vn.dot(xn);return l<0?null:this.at(l/a,i)}applyMatrix4(e){return this.origin.applyMatrix4(e),this.direction.transformDirection(e),this}equals(e){return e.origin.equals(this.origin)&&e.direction.equals(this.direction)}clone(){return new this.constructor().copy(this)}},U=class e{constructor(t,n,r,i,a,o,s,c,l,u,d,f,p,m,h,g){e.prototype.isMatrix4=!0,this.elements=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1],t!==void 0&&this.set(t,n,r,i,a,o,s,c,l,u,d,f,p,m,h,g)}set(e,t,n,r,i,a,o,s,c,l,u,d,f,p,m,h){let g=this.elements;return g[0]=e,g[4]=t,g[8]=n,g[12]=r,g[1]=i,g[5]=a,g[9]=o,g[13]=s,g[2]=c,g[6]=l,g[10]=u,g[14]=d,g[3]=f,g[7]=p,g[11]=m,g[15]=h,this}identity(){return this.set(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1),this}clone(){return new e().fromArray(this.elements)}copy(e){let t=this.elements,n=e.elements;return t[0]=n[0],t[1]=n[1],t[2]=n[2],t[3]=n[3],t[4]=n[4],t[5]=n[5],t[6]=n[6],t[7]=n[7],t[8]=n[8],t[9]=n[9],t[10]=n[10],t[11]=n[11],t[12]=n[12],t[13]=n[13],t[14]=n[14],t[15]=n[15],this}copyPosition(e){let t=this.elements,n=e.elements;return t[12]=n[12],t[13]=n[13],t[14]=n[14],this}setFromMatrix3(e){let t=e.elements;return this.set(t[0],t[3],t[6],0,t[1],t[4],t[7],0,t[2],t[5],t[8],0,0,0,0,1),this}extractBasis(e,t,n){return e.setFromMatrixColumn(this,0),t.setFromMatrixColumn(this,1),n.setFromMatrixColumn(this,2),this}makeBasis(e,t,n){return this.set(e.x,t.x,n.x,0,e.y,t.y,n.y,0,e.z,t.z,n.z,0,0,0,0,1),this}extractRotation(e){let t=this.elements,n=e.elements,r=1/Cn.setFromMatrixColumn(e,0).length(),i=1/Cn.setFromMatrixColumn(e,1).length(),a=1/Cn.setFromMatrixColumn(e,2).length();return t[0]=n[0]*r,t[1]=n[1]*r,t[2]=n[2]*r,t[3]=0,t[4]=n[4]*i,t[5]=n[5]*i,t[6]=n[6]*i,t[7]=0,t[8]=n[8]*a,t[9]=n[9]*a,t[10]=n[10]*a,t[11]=0,t[12]=0,t[13]=0,t[14]=0,t[15]=1,this}makeRotationFromEuler(e){let t=this.elements,n=e.x,r=e.y,i=e.z,a=Math.cos(n),o=Math.sin(n),s=Math.cos(r),c=Math.sin(r),l=Math.cos(i),u=Math.sin(i);if(e.order===`XYZ`){let e=a*l,n=a*u,r=o*l,i=o*u;t[0]=s*l,t[4]=-s*u,t[8]=c,t[1]=n+r*c,t[5]=e-i*c,t[9]=-o*s,t[2]=i-e*c,t[6]=r+n*c,t[10]=a*s}else if(e.order===`YXZ`){let e=s*l,n=s*u,r=c*l,i=c*u;t[0]=e+i*o,t[4]=r*o-n,t[8]=a*c,t[1]=a*u,t[5]=a*l,t[9]=-o,t[2]=n*o-r,t[6]=i+e*o,t[10]=a*s}else if(e.order===`ZXY`){let e=s*l,n=s*u,r=c*l,i=c*u;t[0]=e-i*o,t[4]=-a*u,t[8]=r+n*o,t[1]=n+r*o,t[5]=a*l,t[9]=i-e*o,t[2]=-a*c,t[6]=o,t[10]=a*s}else if(e.order===`ZYX`){let e=a*l,n=a*u,r=o*l,i=o*u;t[0]=s*l,t[4]=r*c-n,t[8]=e*c+i,t[1]=s*u,t[5]=i*c+e,t[9]=n*c-r,t[2]=-c,t[6]=o*s,t[10]=a*s}else if(e.order===`YZX`){let e=a*s,n=a*c,r=o*s,i=o*c;t[0]=s*l,t[4]=i-e*u,t[8]=r*u+n,t[1]=u,t[5]=a*l,t[9]=-o*l,t[2]=-c*l,t[6]=n*u+r,t[10]=e-i*u}else if(e.order===`XZY`){let e=a*s,n=a*c,r=o*s,i=o*c;t[0]=s*l,t[4]=-u,t[8]=c*l,t[1]=e*u+i,t[5]=a*l,t[9]=n*u-r,t[2]=r*u-n,t[6]=o*l,t[10]=i*u+e}return t[3]=0,t[7]=0,t[11]=0,t[12]=0,t[13]=0,t[14]=0,t[15]=1,this}makeRotationFromQuaternion(e){return this.compose(Tn,e,En)}lookAt(e,t,n){let r=this.elements;return kn.subVectors(e,t),kn.lengthSq()===0&&(kn.z=1),kn.normalize(),Dn.crossVectors(n,kn),Dn.lengthSq()===0&&(Math.abs(n.z)===1?kn.x+=1e-4:kn.z+=1e-4,kn.normalize(),Dn.crossVectors(n,kn)),Dn.normalize(),On.crossVectors(kn,Dn),r[0]=Dn.x,r[4]=On.x,r[8]=kn.x,r[1]=Dn.y,r[5]=On.y,r[9]=kn.y,r[2]=Dn.z,r[6]=On.z,r[10]=kn.z,this}multiply(e){return this.multiplyMatrices(this,e)}premultiply(e){return this.multiplyMatrices(e,this)}multiplyMatrices(e,t){let n=e.elements,r=t.elements,i=this.elements,a=n[0],o=n[4],s=n[8],c=n[12],l=n[1],u=n[5],d=n[9],f=n[13],p=n[2],m=n[6],h=n[10],g=n[14],_=n[3],v=n[7],y=n[11],b=n[15],x=r[0],S=r[4],C=r[8],w=r[12],T=r[1],E=r[5],D=r[9],O=r[13],k=r[2],ee=r[6],A=r[10],te=r[14],ne=r[3],j=r[7],M=r[11],N=r[15];return i[0]=a*x+o*T+s*k+c*ne,i[4]=a*S+o*E+s*ee+c*j,i[8]=a*C+o*D+s*A+c*M,i[12]=a*w+o*O+s*te+c*N,i[1]=l*x+u*T+d*k+f*ne,i[5]=l*S+u*E+d*ee+f*j,i[9]=l*C+u*D+d*A+f*M,i[13]=l*w+u*O+d*te+f*N,i[2]=p*x+m*T+h*k+g*ne,i[6]=p*S+m*E+h*ee+g*j,i[10]=p*C+m*D+h*A+g*M,i[14]=p*w+m*O+h*te+g*N,i[3]=_*x+v*T+y*k+b*ne,i[7]=_*S+v*E+y*ee+b*j,i[11]=_*C+v*D+y*A+b*M,i[15]=_*w+v*O+y*te+b*N,this}multiplyScalar(e){let t=this.elements;return t[0]*=e,t[4]*=e,t[8]*=e,t[12]*=e,t[1]*=e,t[5]*=e,t[9]*=e,t[13]*=e,t[2]*=e,t[6]*=e,t[10]*=e,t[14]*=e,t[3]*=e,t[7]*=e,t[11]*=e,t[15]*=e,this}determinant(){let e=this.elements,t=e[0],n=e[4],r=e[8],i=e[12],a=e[1],o=e[5],s=e[9],c=e[13],l=e[2],u=e[6],d=e[10],f=e[14],p=e[3],m=e[7],h=e[11],g=e[15];return p*(+i*s*u-r*c*u-i*o*d+n*c*d+r*o*f-n*s*f)+m*(+t*s*f-t*c*d+i*a*d-r*a*f+r*c*l-i*s*l)+h*(+t*c*u-t*o*f-i*a*u+n*a*f+i*o*l-n*c*l)+g*(-r*o*l-t*s*u+t*o*d+r*a*u-n*a*d+n*s*l)}transpose(){let e=this.elements,t;return t=e[1],e[1]=e[4],e[4]=t,t=e[2],e[2]=e[8],e[8]=t,t=e[6],e[6]=e[9],e[9]=t,t=e[3],e[3]=e[12],e[12]=t,t=e[7],e[7]=e[13],e[13]=t,t=e[11],e[11]=e[14],e[14]=t,this}setPosition(e,t,n){let r=this.elements;return e.isVector3?(r[12]=e.x,r[13]=e.y,r[14]=e.z):(r[12]=e,r[13]=t,r[14]=n),this}invert(){let e=this.elements,t=e[0],n=e[1],r=e[2],i=e[3],a=e[4],o=e[5],s=e[6],c=e[7],l=e[8],u=e[9],d=e[10],f=e[11],p=e[12],m=e[13],h=e[14],g=e[15],_=u*h*c-m*d*c+m*s*f-o*h*f-u*s*g+o*d*g,v=p*d*c-l*h*c-p*s*f+a*h*f+l*s*g-a*d*g,y=l*m*c-p*u*c+p*o*f-a*m*f-l*o*g+a*u*g,b=p*u*s-l*m*s-p*o*d+a*m*d+l*o*h-a*u*h,x=t*_+n*v+r*y+i*b;if(x===0)return this.set(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);let S=1/x;return e[0]=_*S,e[1]=(m*d*i-u*h*i-m*r*f+n*h*f+u*r*g-n*d*g)*S,e[2]=(o*h*i-m*s*i+m*r*c-n*h*c-o*r*g+n*s*g)*S,e[3]=(u*s*i-o*d*i-u*r*c+n*d*c+o*r*f-n*s*f)*S,e[4]=v*S,e[5]=(l*h*i-p*d*i+p*r*f-t*h*f-l*r*g+t*d*g)*S,e[6]=(p*s*i-a*h*i-p*r*c+t*h*c+a*r*g-t*s*g)*S,e[7]=(a*d*i-l*s*i+l*r*c-t*d*c-a*r*f+t*s*f)*S,e[8]=y*S,e[9]=(p*u*i-l*m*i-p*n*f+t*m*f+l*n*g-t*u*g)*S,e[10]=(a*m*i-p*o*i+p*n*c-t*m*c-a*n*g+t*o*g)*S,e[11]=(l*o*i-a*u*i-l*n*c+t*u*c+a*n*f-t*o*f)*S,e[12]=b*S,e[13]=(l*m*r-p*u*r+p*n*d-t*m*d-l*n*h+t*u*h)*S,e[14]=(p*o*r-a*m*r-p*n*s+t*m*s+a*n*h-t*o*h)*S,e[15]=(a*u*r-l*o*r+l*n*s-t*u*s-a*n*d+t*o*d)*S,this}scale(e){let t=this.elements,n=e.x,r=e.y,i=e.z;return t[0]*=n,t[4]*=r,t[8]*=i,t[1]*=n,t[5]*=r,t[9]*=i,t[2]*=n,t[6]*=r,t[10]*=i,t[3]*=n,t[7]*=r,t[11]*=i,this}getMaxScaleOnAxis(){let e=this.elements,t=e[0]*e[0]+e[1]*e[1]+e[2]*e[2],n=e[4]*e[4]+e[5]*e[5]+e[6]*e[6],r=e[8]*e[8]+e[9]*e[9]+e[10]*e[10];return Math.sqrt(Math.max(t,n,r))}makeTranslation(e,t,n){return e.isVector3?this.set(1,0,0,e.x,0,1,0,e.y,0,0,1,e.z,0,0,0,1):this.set(1,0,0,e,0,1,0,t,0,0,1,n,0,0,0,1),this}makeRotationX(e){let t=Math.cos(e),n=Math.sin(e);return this.set(1,0,0,0,0,t,-n,0,0,n,t,0,0,0,0,1),this}makeRotationY(e){let t=Math.cos(e),n=Math.sin(e);return this.set(t,0,n,0,0,1,0,0,-n,0,t,0,0,0,0,1),this}makeRotationZ(e){let t=Math.cos(e),n=Math.sin(e);return this.set(t,-n,0,0,n,t,0,0,0,0,1,0,0,0,0,1),this}makeRotationAxis(e,t){let n=Math.cos(t),r=Math.sin(t),i=1-n,a=e.x,o=e.y,s=e.z,c=i*a,l=i*o;return this.set(c*a+n,c*o-r*s,c*s+r*o,0,c*o+r*s,l*o+n,l*s-r*a,0,c*s-r*o,l*s+r*a,i*s*s+n,0,0,0,0,1),this}makeScale(e,t,n){return this.set(e,0,0,0,0,t,0,0,0,0,n,0,0,0,0,1),this}makeShear(e,t,n,r,i,a){return this.set(1,n,i,0,e,1,a,0,t,r,1,0,0,0,0,1),this}compose(e,t,n){let r=this.elements,i=t._x,a=t._y,o=t._z,s=t._w,c=i+i,l=a+a,u=o+o,d=i*c,f=i*l,p=i*u,m=a*l,h=a*u,g=o*u,_=s*c,v=s*l,y=s*u,b=n.x,x=n.y,S=n.z;return r[0]=(1-(m+g))*b,r[1]=(f+y)*b,r[2]=(p-v)*b,r[3]=0,r[4]=(f-y)*x,r[5]=(1-(d+g))*x,r[6]=(h+_)*x,r[7]=0,r[8]=(p+v)*S,r[9]=(h-_)*S,r[10]=(1-(d+m))*S,r[11]=0,r[12]=e.x,r[13]=e.y,r[14]=e.z,r[15]=1,this}decompose(e,t,n){let r=this.elements,i=Cn.set(r[0],r[1],r[2]).length(),a=Cn.set(r[4],r[5],r[6]).length(),o=Cn.set(r[8],r[9],r[10]).length();this.determinant()<0&&(i=-i),e.x=r[12],e.y=r[13],e.z=r[14],wn.copy(this);let s=1/i,c=1/a,l=1/o;return wn.elements[0]*=s,wn.elements[1]*=s,wn.elements[2]*=s,wn.elements[4]*=c,wn.elements[5]*=c,wn.elements[6]*=c,wn.elements[8]*=l,wn.elements[9]*=l,wn.elements[10]*=l,t.setFromRotationMatrix(wn),n.x=i,n.y=a,n.z=o,this}makePerspective(e,t,n,r,i,a,o=We){let s=this.elements,c=2*i/(t-e),l=2*i/(n-r),u=(t+e)/(t-e),d=(n+r)/(n-r),f,p;if(o===2e3)f=-(a+i)/(a-i),p=-2*a*i/(a-i);else if(o===2001)f=-a/(a-i),p=-a*i/(a-i);else throw Error(`THREE.Matrix4.makePerspective(): Invalid coordinate system: `+o);return s[0]=c,s[4]=0,s[8]=u,s[12]=0,s[1]=0,s[5]=l,s[9]=d,s[13]=0,s[2]=0,s[6]=0,s[10]=f,s[14]=p,s[3]=0,s[7]=0,s[11]=-1,s[15]=0,this}makeOrthographic(e,t,n,r,i,a,o=We){let s=this.elements,c=1/(t-e),l=1/(n-r),u=1/(a-i),d=(t+e)*c,f=(n+r)*l,p,m;if(o===2e3)p=(a+i)*u,m=-2*u;else if(o===2001)p=i*u,m=-1*u;else throw Error(`THREE.Matrix4.makeOrthographic(): Invalid coordinate system: `+o);return s[0]=2*c,s[4]=0,s[8]=0,s[12]=-d,s[1]=0,s[5]=2*l,s[9]=0,s[13]=-f,s[2]=0,s[6]=0,s[10]=m,s[14]=-p,s[3]=0,s[7]=0,s[11]=0,s[15]=1,this}equals(e){let t=this.elements,n=e.elements;for(let e=0;e<16;e++)if(t[e]!==n[e])return!1;return!0}fromArray(e,t=0){for(let n=0;n<16;n++)this.elements[n]=e[n+t];return this}toArray(e=[],t=0){let n=this.elements;return e[t]=n[0],e[t+1]=n[1],e[t+2]=n[2],e[t+3]=n[3],e[t+4]=n[4],e[t+5]=n[5],e[t+6]=n[6],e[t+7]=n[7],e[t+8]=n[8],e[t+9]=n[9],e[t+10]=n[10],e[t+11]=n[11],e[t+12]=n[12],e[t+13]=n[13],e[t+14]=n[14],e[t+15]=n[15],e}},Cn=new H,wn=new U,Tn=new H(0,0,0),En=new H(1,1,1),Dn=new H,On=new H,kn=new H,An=new U,jn=new V,Mn=class e{constructor(t=0,n=0,r=0,i=e.DEFAULT_ORDER){this.isEuler=!0,this._x=t,this._y=n,this._z=r,this._order=i}get x(){return this._x}set x(e){this._x=e,this._onChangeCallback()}get y(){return this._y}set y(e){this._y=e,this._onChangeCallback()}get z(){return this._z}set z(e){this._z=e,this._onChangeCallback()}get order(){return this._order}set order(e){this._order=e,this._onChangeCallback()}set(e,t,n,r=this._order){return this._x=e,this._y=t,this._z=n,this._order=r,this._onChangeCallback(),this}clone(){return new this.constructor(this._x,this._y,this._z,this._order)}copy(e){return this._x=e._x,this._y=e._y,this._z=e._z,this._order=e._order,this._onChangeCallback(),this}setFromRotationMatrix(e,t=this._order,n=!0){let r=e.elements,i=r[0],a=r[4],o=r[8],s=r[1],c=r[5],l=r[9],u=r[2],d=r[6],f=r[10];switch(t){case`XYZ`:this._y=Math.asin(Ze(o,-1,1)),Math.abs(o)<.9999999?(this._x=Math.atan2(-l,f),this._z=Math.atan2(-a,i)):(this._x=Math.atan2(d,c),this._z=0);break;case`YXZ`:this._x=Math.asin(-Ze(l,-1,1)),Math.abs(l)<.9999999?(this._y=Math.atan2(o,f),this._z=Math.atan2(s,c)):(this._y=Math.atan2(-u,i),this._z=0);break;case`ZXY`:this._x=Math.asin(Ze(d,-1,1)),Math.abs(d)<.9999999?(this._y=Math.atan2(-u,f),this._z=Math.atan2(-a,c)):(this._y=0,this._z=Math.atan2(s,i));break;case`ZYX`:this._y=Math.asin(-Ze(u,-1,1)),Math.abs(u)<.9999999?(this._x=Math.atan2(d,f),this._z=Math.atan2(s,i)):(this._x=0,this._z=Math.atan2(-a,c));break;case`YZX`:this._z=Math.asin(Ze(s,-1,1)),Math.abs(s)<.9999999?(this._x=Math.atan2(-l,c),this._y=Math.atan2(-u,i)):(this._x=0,this._y=Math.atan2(o,f));break;case`XZY`:this._z=Math.asin(-Ze(a,-1,1)),Math.abs(a)<.9999999?(this._x=Math.atan2(d,c),this._y=Math.atan2(o,i)):(this._x=Math.atan2(-l,f),this._y=0);break;default:console.warn(`THREE.Euler: .setFromRotationMatrix() encountered an unknown order: `+t)}return this._order=t,n===!0&&this._onChangeCallback(),this}setFromQuaternion(e,t,n){return An.makeRotationFromQuaternion(e),this.setFromRotationMatrix(An,t,n)}setFromVector3(e,t=this._order){return this.set(e.x,e.y,e.z,t)}reorder(e){return jn.setFromEuler(this),this.setFromQuaternion(jn,e)}equals(e){return e._x===this._x&&e._y===this._y&&e._z===this._z&&e._order===this._order}fromArray(e){return this._x=e[0],this._y=e[1],this._z=e[2],e[3]!==void 0&&(this._order=e[3]),this._onChangeCallback(),this}toArray(e=[],t=0){return e[t]=this._x,e[t+1]=this._y,e[t+2]=this._z,e[t+3]=this._order,e}_onChange(e){return this._onChangeCallback=e,this}_onChangeCallback(){}*[Symbol.iterator](){yield this._x,yield this._y,yield this._z,yield this._order}};Mn.DEFAULT_ORDER=`XYZ`;var Nn=class{constructor(){this.mask=1}set(e){this.mask=(1<<e|0)>>>0}enable(e){this.mask|=1<<e|0}enableAll(){this.mask=-1}toggle(e){this.mask^=1<<e|0}disable(e){this.mask&=~(1<<e|0)}disableAll(){this.mask=0}test(e){return(this.mask&e.mask)!==0}isEnabled(e){return!!(this.mask&(1<<e|0))}},Pn=0,Fn=new H,In=new V,Ln=new U,Rn=new H,zn=new H,Bn=new H,Vn=new V,Hn=new H(1,0,0),Un=new H(0,1,0),Wn=new H(0,0,1),Gn={type:`added`},Kn={type:`removed`},qn={type:`childadded`,child:null},Jn={type:`childremoved`,child:null},Yn=class e extends Ge{constructor(){super(),this.isObject3D=!0,Object.defineProperty(this,"id",{value:Pn++}),this.uuid=Xe(),this.name=``,this.type=`Object3D`,this.parent=null,this.children=[],this.up=e.DEFAULT_UP.clone();let t=new H,n=new Mn,r=new V,i=new H(1,1,1);function a(){r.setFromEuler(n,!1)}function o(){n.setFromQuaternion(r,void 0,!1)}n._onChange(a),r._onChange(o),Object.defineProperties(this,{position:{configurable:!0,enumerable:!0,value:t},rotation:{configurable:!0,enumerable:!0,value:n},quaternion:{configurable:!0,enumerable:!0,value:r},scale:{configurable:!0,enumerable:!0,value:i},modelViewMatrix:{value:new U},normalMatrix:{value:new z}}),this.matrix=new U,this.matrixWorld=new U,this.matrixAutoUpdate=e.DEFAULT_MATRIX_AUTO_UPDATE,this.matrixWorldAutoUpdate=e.DEFAULT_MATRIX_WORLD_AUTO_UPDATE,this.matrixWorldNeedsUpdate=!1,this.layers=new Nn,this.visible=!0,this.castShadow=!1,this.receiveShadow=!1,this.frustumCulled=!0,this.renderOrder=0,this.animations=[],this.userData={}}onBeforeShadow(){}onAfterShadow(){}onBeforeRender(){}onAfterRender(){}applyMatrix4(e){this.matrixAutoUpdate&&this.updateMatrix(),this.matrix.premultiply(e),this.matrix.decompose(this.position,this.quaternion,this.scale)}applyQuaternion(e){return this.quaternion.premultiply(e),this}setRotationFromAxisAngle(e,t){this.quaternion.setFromAxisAngle(e,t)}setRotationFromEuler(e){this.quaternion.setFromEuler(e,!0)}setRotationFromMatrix(e){this.quaternion.setFromRotationMatrix(e)}setRotationFromQuaternion(e){this.quaternion.copy(e)}rotateOnAxis(e,t){return In.setFromAxisAngle(e,t),this.quaternion.multiply(In),this}rotateOnWorldAxis(e,t){return In.setFromAxisAngle(e,t),this.quaternion.premultiply(In),this}rotateX(e){return this.rotateOnAxis(Hn,e)}rotateY(e){return this.rotateOnAxis(Un,e)}rotateZ(e){return this.rotateOnAxis(Wn,e)}translateOnAxis(e,t){return Fn.copy(e).applyQuaternion(this.quaternion),this.position.add(Fn.multiplyScalar(t)),this}translateX(e){return this.translateOnAxis(Hn,e)}translateY(e){return this.translateOnAxis(Un,e)}translateZ(e){return this.translateOnAxis(Wn,e)}localToWorld(e){return this.updateWorldMatrix(!0,!1),e.applyMatrix4(this.matrixWorld)}worldToLocal(e){return this.updateWorldMatrix(!0,!1),e.applyMatrix4(Ln.copy(this.matrixWorld).invert())}lookAt(e,t,n){e.isVector3?Rn.copy(e):Rn.set(e,t,n);let r=this.parent;this.updateWorldMatrix(!0,!1),zn.setFromMatrixPosition(this.matrixWorld),this.isCamera||this.isLight?Ln.lookAt(zn,Rn,this.up):Ln.lookAt(Rn,zn,this.up),this.quaternion.setFromRotationMatrix(Ln),r&&(Ln.extractRotation(r.matrixWorld),In.setFromRotationMatrix(Ln),this.quaternion.premultiply(In.invert()))}add(e){if(arguments.length>1){for(let e=0;e<arguments.length;e++)this.add(arguments[e]);return this}return e===this?(console.error(`THREE.Object3D.add: object can't be added as a child of itself.`,e),this):(e&&e.isObject3D?(e.removeFromParent(),e.parent=this,this.children.push(e),e.dispatchEvent(Gn),qn.child=e,this.dispatchEvent(qn),qn.child=null):console.error(`THREE.Object3D.add: object not an instance of THREE.Object3D.`,e),this)}remove(e){if(arguments.length>1){for(let e=0;e<arguments.length;e++)this.remove(arguments[e]);return this}let t=this.children.indexOf(e);return t!==-1&&(e.parent=null,this.children.splice(t,1),e.dispatchEvent(Kn),Jn.child=e,this.dispatchEvent(Jn),Jn.child=null),this}removeFromParent(){let e=this.parent;return e!==null&&e.remove(this),this}clear(){return this.remove(...this.children)}attach(e){return this.updateWorldMatrix(!0,!1),Ln.copy(this.matrixWorld).invert(),e.parent!==null&&(e.parent.updateWorldMatrix(!0,!1),Ln.multiply(e.parent.matrixWorld)),e.applyMatrix4(Ln),e.removeFromParent(),e.parent=this,this.children.push(e),e.updateWorldMatrix(!1,!0),e.dispatchEvent(Gn),qn.child=e,this.dispatchEvent(qn),qn.child=null,this}getObjectById(e){return this.getObjectByProperty(`id`,e)}getObjectByName(e){return this.getObjectByProperty(`name`,e)}getObjectByProperty(e,t){if(this[e]===t)return this;for(let n=0,r=this.children.length;n<r;n++){let r=this.children[n].getObjectByProperty(e,t);if(r!==void 0)return r}}getObjectsByProperty(e,t,n=[]){this[e]===t&&n.push(this);let r=this.children;for(let i=0,a=r.length;i<a;i++)r[i].getObjectsByProperty(e,t,n);return n}getWorldPosition(e){return this.updateWorldMatrix(!0,!1),e.setFromMatrixPosition(this.matrixWorld)}getWorldQuaternion(e){return this.updateWorldMatrix(!0,!1),this.matrixWorld.decompose(zn,e,Bn),e}getWorldScale(e){return this.updateWorldMatrix(!0,!1),this.matrixWorld.decompose(zn,Vn,e),e}getWorldDirection(e){this.updateWorldMatrix(!0,!1);let t=this.matrixWorld.elements;return e.set(t[8],t[9],t[10]).normalize()}raycast(){}traverse(e){e(this);let t=this.children;for(let n=0,r=t.length;n<r;n++)t[n].traverse(e)}traverseVisible(e){if(this.visible===!1)return;e(this);let t=this.children;for(let n=0,r=t.length;n<r;n++)t[n].traverseVisible(e)}traverseAncestors(e){let t=this.parent;t!==null&&(e(t),t.traverseAncestors(e))}updateMatrix(){this.matrix.compose(this.position,this.quaternion,this.scale),this.matrixWorldNeedsUpdate=!0}updateMatrixWorld(e){this.matrixAutoUpdate&&this.updateMatrix(),(this.matrixWorldNeedsUpdate||e)&&(this.matrixWorldAutoUpdate===!0&&(this.parent===null?this.matrixWorld.copy(this.matrix):this.matrixWorld.multiplyMatrices(this.parent.matrixWorld,this.matrix)),this.matrixWorldNeedsUpdate=!1,e=!0);let t=this.children;for(let n=0,r=t.length;n<r;n++)t[n].updateMatrixWorld(e)}updateWorldMatrix(e,t){let n=this.parent;if(e===!0&&n!==null&&n.updateWorldMatrix(!0,!1),this.matrixAutoUpdate&&this.updateMatrix(),this.matrixWorldAutoUpdate===!0&&(this.parent===null?this.matrixWorld.copy(this.matrix):this.matrixWorld.multiplyMatrices(this.parent.matrixWorld,this.matrix)),t===!0){let e=this.children;for(let t=0,n=e.length;t<n;t++)e[t].updateWorldMatrix(!1,!0)}}toJSON(e){let t=e===void 0||typeof e==`string`,n={};t&&(e={geometries:{},materials:{},textures:{},images:{},shapes:{},skeletons:{},animations:{},nodes:{}},n.metadata={version:4.6,type:`Object`,generator:`Object3D.toJSON`});let r={};r.uuid=this.uuid,r.type=this.type,this.name!==``&&(r.name=this.name),this.castShadow===!0&&(r.castShadow=!0),this.receiveShadow===!0&&(r.receiveShadow=!0),this.visible===!1&&(r.visible=!1),this.frustumCulled===!1&&(r.frustumCulled=!1),this.renderOrder!==0&&(r.renderOrder=this.renderOrder),Object.keys(this.userData).length>0&&(r.userData=this.userData),r.layers=this.layers.mask,r.matrix=this.matrix.toArray(),r.up=this.up.toArray(),this.matrixAutoUpdate===!1&&(r.matrixAutoUpdate=!1),this.isInstancedMesh&&(r.type=`InstancedMesh`,r.count=this.count,r.instanceMatrix=this.instanceMatrix.toJSON(),this.instanceColor!==null&&(r.instanceColor=this.instanceColor.toJSON())),this.isBatchedMesh&&(r.type=`BatchedMesh`,r.perObjectFrustumCulled=this.perObjectFrustumCulled,r.sortObjects=this.sortObjects,r.drawRanges=this._drawRanges,r.reservedRanges=this._reservedRanges,r.visibility=this._visibility,r.active=this._active,r.bounds=this._bounds.map(e=>({boxInitialized:e.boxInitialized,boxMin:e.box.min.toArray(),boxMax:e.box.max.toArray(),sphereInitialized:e.sphereInitialized,sphereRadius:e.sphere.radius,sphereCenter:e.sphere.center.toArray()})),r.maxInstanceCount=this._maxInstanceCount,r.maxVertexCount=this._maxVertexCount,r.maxIndexCount=this._maxIndexCount,r.geometryInitialized=this._geometryInitialized,r.geometryCount=this._geometryCount,r.matricesTexture=this._matricesTexture.toJSON(e),this._colorsTexture!==null&&(r.colorsTexture=this._colorsTexture.toJSON(e)),this.boundingSphere!==null&&(r.boundingSphere={center:r.boundingSphere.center.toArray(),radius:r.boundingSphere.radius}),this.boundingBox!==null&&(r.boundingBox={min:r.boundingBox.min.toArray(),max:r.boundingBox.max.toArray()}));function i(t,n){return t[n.uuid]===void 0&&(t[n.uuid]=n.toJSON(e)),n.uuid}if(this.isScene)this.background&&(this.background.isColor?r.background=this.background.toJSON():this.background.isTexture&&(r.background=this.background.toJSON(e).uuid)),this.environment&&this.environment.isTexture&&this.environment.isRenderTargetTexture!==!0&&(r.environment=this.environment.toJSON(e).uuid);else if(this.isMesh||this.isLine||this.isPoints){r.geometry=i(e.geometries,this.geometry);let t=this.geometry.parameters;if(t!==void 0&&t.shapes!==void 0){let n=t.shapes;if(Array.isArray(n))for(let t=0,r=n.length;t<r;t++){let r=n[t];i(e.shapes,r)}else i(e.shapes,n)}}if(this.isSkinnedMesh&&(r.bindMode=this.bindMode,r.bindMatrix=this.bindMatrix.toArray(),this.skeleton!==void 0&&(i(e.skeletons,this.skeleton),r.skeleton=this.skeleton.uuid)),this.material!==void 0){if(Array.isArray(this.material)){let t=[];for(let n=0,r=this.material.length;n<r;n++)t.push(i(e.materials,this.material[n]));r.material=t}else r.material=i(e.materials,this.material)}if(this.children.length>0){r.children=[];for(let t=0;t<this.children.length;t++)r.children.push(this.children[t].toJSON(e).object)}if(this.animations.length>0){r.animations=[];for(let t=0;t<this.animations.length;t++){let n=this.animations[t];r.animations.push(i(e.animations,n))}}if(t){let t=a(e.geometries),r=a(e.materials),i=a(e.textures),o=a(e.images),s=a(e.shapes),c=a(e.skeletons),l=a(e.animations),u=a(e.nodes);t.length>0&&(n.geometries=t),r.length>0&&(n.materials=r),i.length>0&&(n.textures=i),o.length>0&&(n.images=o),s.length>0&&(n.shapes=s),c.length>0&&(n.skeletons=c),l.length>0&&(n.animations=l),u.length>0&&(n.nodes=u)}return n.object=r,n;function a(e){let t=[];for(let n in e){let r=e[n];delete r.metadata,t.push(r)}return t}}clone(e){return new this.constructor().copy(this,e)}copy(e,t=!0){if(this.name=e.name,this.up.copy(e.up),this.position.copy(e.position),this.rotation.order=e.rotation.order,this.quaternion.copy(e.quaternion),this.scale.copy(e.scale),this.matrix.copy(e.matrix),this.matrixWorld.copy(e.matrixWorld),this.matrixAutoUpdate=e.matrixAutoUpdate,this.matrixWorldAutoUpdate=e.matrixWorldAutoUpdate,this.matrixWorldNeedsUpdate=e.matrixWorldNeedsUpdate,this.layers.mask=e.layers.mask,this.visible=e.visible,this.castShadow=e.castShadow,this.receiveShadow=e.receiveShadow,this.frustumCulled=e.frustumCulled,this.renderOrder=e.renderOrder,this.animations=e.animations.slice(),this.userData=JSON.parse(JSON.stringify(e.userData)),t===!0)for(let t=0;t<e.children.length;t++){let n=e.children[t];this.add(n.clone())}return this}};Yn.DEFAULT_UP=new H(0,1,0),Yn.DEFAULT_MATRIX_AUTO_UPDATE=!0,Yn.DEFAULT_MATRIX_WORLD_AUTO_UPDATE=!0;var Xn=new H,Zn=new H,Qn=new H,$n=new H,er=new H,tr=new H,nr=new H,rr=new H,ir=new H,ar=new H,or=new B,sr=new B,cr=new B,lr=class e{constructor(e=new H,t=new H,n=new H){this.a=e,this.b=t,this.c=n}static getNormal(e,t,n,r){r.subVectors(n,t),Xn.subVectors(e,t),r.cross(Xn);let i=r.lengthSq();return i>0?r.multiplyScalar(1/Math.sqrt(i)):r.set(0,0,0)}static getBarycoord(e,t,n,r,i){Xn.subVectors(r,t),Zn.subVectors(n,t),Qn.subVectors(e,t);let a=Xn.dot(Xn),o=Xn.dot(Zn),s=Xn.dot(Qn),c=Zn.dot(Zn),l=Zn.dot(Qn),u=a*c-o*o;if(u===0)return i.set(0,0,0),null;let d=1/u,f=(c*s-o*l)*d,p=(a*l-o*s)*d;return i.set(1-f-p,p,f)}static containsPoint(e,t,n,r){return this.getBarycoord(e,t,n,r,$n)!==null&&$n.x>=0&&$n.y>=0&&$n.x+$n.y<=1}static getInterpolation(e,t,n,r,i,a,o,s){return this.getBarycoord(e,t,n,r,$n)===null?(s.x=0,s.y=0,`z`in s&&(s.z=0),`w`in s&&(s.w=0),null):(s.setScalar(0),s.addScaledVector(i,$n.x),s.addScaledVector(a,$n.y),s.addScaledVector(o,$n.z),s)}static getInterpolatedAttribute(e,t,n,r,i,a){return or.setScalar(0),sr.setScalar(0),cr.setScalar(0),or.fromBufferAttribute(e,t),sr.fromBufferAttribute(e,n),cr.fromBufferAttribute(e,r),a.setScalar(0),a.addScaledVector(or,i.x),a.addScaledVector(sr,i.y),a.addScaledVector(cr,i.z),a}static isFrontFacing(e,t,n,r){return Xn.subVectors(n,t),Zn.subVectors(e,t),Xn.cross(Zn).dot(r)<0}set(e,t,n){return this.a.copy(e),this.b.copy(t),this.c.copy(n),this}setFromPointsAndIndices(e,t,n,r){return this.a.copy(e[t]),this.b.copy(e[n]),this.c.copy(e[r]),this}setFromAttributeAndIndices(e,t,n,r){return this.a.fromBufferAttribute(e,t),this.b.fromBufferAttribute(e,n),this.c.fromBufferAttribute(e,r),this}clone(){return new this.constructor().copy(this)}copy(e){return this.a.copy(e.a),this.b.copy(e.b),this.c.copy(e.c),this}getArea(){return Xn.subVectors(this.c,this.b),Zn.subVectors(this.a,this.b),Xn.cross(Zn).length()*.5}getMidpoint(e){return e.addVectors(this.a,this.b).add(this.c).multiplyScalar(1/3)}getNormal(t){return e.getNormal(this.a,this.b,this.c,t)}getPlane(e){return e.setFromCoplanarPoints(this.a,this.b,this.c)}getBarycoord(t,n){return e.getBarycoord(t,this.a,this.b,this.c,n)}getInterpolation(t,n,r,i,a){return e.getInterpolation(t,this.a,this.b,this.c,n,r,i,a)}containsPoint(t){return e.containsPoint(t,this.a,this.b,this.c)}isFrontFacing(t){return e.isFrontFacing(this.a,this.b,this.c,t)}intersectsBox(e){return e.intersectsTriangle(this)}closestPointToPoint(e,t){let n=this.a,r=this.b,i=this.c,a,o;er.subVectors(r,n),tr.subVectors(i,n),rr.subVectors(e,n);let s=er.dot(rr),c=tr.dot(rr);if(s<=0&&c<=0)return t.copy(n);ir.subVectors(e,r);let l=er.dot(ir),u=tr.dot(ir);if(l>=0&&u<=l)return t.copy(r);let d=s*u-l*c;if(d<=0&&s>=0&&l<=0)return a=s/(s-l),t.copy(n).addScaledVector(er,a);ar.subVectors(e,i);let f=er.dot(ar),p=tr.dot(ar);if(p>=0&&f<=p)return t.copy(i);let m=f*c-s*p;if(m<=0&&c>=0&&p<=0)return o=c/(c-p),t.copy(n).addScaledVector(tr,o);let h=l*p-f*u;if(h<=0&&u-l>=0&&f-p>=0)return nr.subVectors(i,r),o=(u-l)/(u-l+(f-p)),t.copy(r).addScaledVector(nr,o);let g=1/(h+m+d);return a=m*g,o=d*g,t.copy(n).addScaledVector(er,a).addScaledVector(tr,o)}equals(e){return e.a.equals(this.a)&&e.b.equals(this.b)&&e.c.equals(this.c)}},ur={aliceblue:15792383,antiquewhite:16444375,aqua:65535,aquamarine:8388564,azure:15794175,beige:16119260,bisque:16770244,black:0,blanchedalmond:16772045,blue:255,blueviolet:9055202,brown:10824234,burlywood:14596231,cadetblue:6266528,chartreuse:8388352,chocolate:13789470,coral:16744272,cornflowerblue:6591981,cornsilk:16775388,crimson:14423100,cyan:65535,darkblue:139,darkcyan:35723,darkgoldenrod:12092939,darkgray:11119017,darkgreen:25600,darkgrey:11119017,darkkhaki:12433259,darkmagenta:9109643,darkolivegreen:5597999,darkorange:16747520,darkorchid:10040012,darkred:9109504,darksalmon:15308410,darkseagreen:9419919,darkslateblue:4734347,darkslategray:3100495,darkslategrey:3100495,darkturquoise:52945,darkviolet:9699539,deeppink:16716947,deepskyblue:49151,dimgray:6908265,dimgrey:6908265,dodgerblue:2003199,firebrick:11674146,floralwhite:16775920,forestgreen:2263842,fuchsia:16711935,gainsboro:14474460,ghostwhite:16316671,gold:16766720,goldenrod:14329120,gray:8421504,green:32768,greenyellow:11403055,grey:8421504,honeydew:15794160,hotpink:16738740,indianred:13458524,indigo:4915330,ivory:16777200,khaki:15787660,lavender:15132410,lavenderblush:16773365,lawngreen:8190976,lemonchiffon:16775885,lightblue:11393254,lightcoral:15761536,lightcyan:14745599,lightgoldenrodyellow:16448210,lightgray:13882323,lightgreen:9498256,lightgrey:13882323,lightpink:16758465,lightsalmon:16752762,lightseagreen:2142890,lightskyblue:8900346,lightslategray:7833753,lightslategrey:7833753,lightsteelblue:11584734,lightyellow:16777184,lime:65280,limegreen:3329330,linen:16445670,magenta:16711935,maroon:8388608,mediumaquamarine:6737322,mediumblue:205,mediumorchid:12211667,mediumpurple:9662683,mediumseagreen:3978097,mediumslateblue:8087790,mediumspringgreen:64154,mediumturquoise:4772300,mediumvioletred:13047173,midnightblue:1644912,mintcream:16121850,mistyrose:16770273,moccasin:16770229,navajowhite:16768685,navy:128,oldlace:16643558,olive:8421376,olivedrab:7048739,orange:16753920,orangered:16729344,orchid:14315734,palegoldenrod:15657130,palegreen:10025880,paleturquoise:11529966,palevioletred:14381203,papayawhip:16773077,peachpuff:16767673,peru:13468991,pink:16761035,plum:14524637,powderblue:11591910,purple:8388736,rebeccapurple:6697881,red:16711680,rosybrown:12357519,royalblue:4286945,saddlebrown:9127187,salmon:16416882,sandybrown:16032864,seagreen:3050327,seashell:16774638,sienna:10506797,silver:12632256,skyblue:8900331,slateblue:6970061,slategray:7372944,slategrey:7372944,snow:16775930,springgreen:65407,steelblue:4620980,tan:13808780,teal:32896,thistle:14204888,tomato:16737095,turquoise:4251856,violet:15631086,wheat:16113331,white:16777215,whitesmoke:16119285,yellow:16776960,yellowgreen:10145074},dr={h:0,s:0,l:0},fr={h:0,s:0,l:0};function pr(e,t,n){return n<0&&(n+=1),n>1&&--n,n<1/6?e+(t-e)*6*n:n<1/2?t:n<2/3?e+(t-e)*6*(2/3-n):e}var W=class{constructor(e,t,n){return this.isColor=!0,this.r=1,this.g=1,this.b=1,this.set(e,t,n)}set(e,t,n){if(t===void 0&&n===void 0){let t=e;t&&t.isColor?this.copy(t):typeof t==`number`?this.setHex(t):typeof t==`string`&&this.setStyle(t)}else this.setRGB(e,t,n);return this}setScalar(e){return this.r=e,this.g=e,this.b=e,this}setHex(e,t=Re){return e=Math.floor(e),this.r=(e>>16&255)/255,this.g=(e>>8&255)/255,this.b=(e&255)/255,Ot.toWorkingColorSpace(this,t),this}setRGB(e,t,n,r=Ot.workingColorSpace){return this.r=e,this.g=t,this.b=n,Ot.toWorkingColorSpace(this,r),this}setHSL(e,t,n,r=Ot.workingColorSpace){if(e=Qe(e,1),t=Ze(t,0,1),n=Ze(n,0,1),t===0)this.r=this.g=this.b=n;else{let r=n<=.5?n*(1+t):n+t-n*t,i=2*n-r;this.r=pr(i,r,e+1/3),this.g=pr(i,r,e),this.b=pr(i,r,e-1/3)}return Ot.toWorkingColorSpace(this,r),this}setStyle(e,t=Re){function n(t){t!==void 0&&parseFloat(t)<1&&console.warn(`THREE.Color: Alpha component of `+e+` will be ignored.`)}let r;if(r=/^(\w+)\(([^\)]*)\)/.exec(e)){let i,a=r[1],o=r[2];switch(a){case`rgb`:case`rgba`:if(i=/^\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o))return n(i[4]),this.setRGB(Math.min(255,parseInt(i[1],10))/255,Math.min(255,parseInt(i[2],10))/255,Math.min(255,parseInt(i[3],10))/255,t);if(i=/^\s*(\d+)\%\s*,\s*(\d+)\%\s*,\s*(\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o))return n(i[4]),this.setRGB(Math.min(100,parseInt(i[1],10))/100,Math.min(100,parseInt(i[2],10))/100,Math.min(100,parseInt(i[3],10))/100,t);break;case`hsl`:case`hsla`:if(i=/^\s*(\d*\.?\d+)\s*,\s*(\d*\.?\d+)\%\s*,\s*(\d*\.?\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o))return n(i[4]),this.setHSL(parseFloat(i[1])/360,parseFloat(i[2])/100,parseFloat(i[3])/100,t);break;default:console.warn(`THREE.Color: Unknown color model `+e)}}else if(r=/^\#([A-Fa-f\d]+)$/.exec(e)){let n=r[1],i=n.length;if(i===3)return this.setRGB(parseInt(n.charAt(0),16)/15,parseInt(n.charAt(1),16)/15,parseInt(n.charAt(2),16)/15,t);if(i===6)return this.setHex(parseInt(n,16),t);console.warn(`THREE.Color: Invalid hex color `+e)}else if(e&&e.length>0)return this.setColorName(e,t);return this}setColorName(e,t=Re){let n=ur[e.toLowerCase()];return n===void 0?console.warn(`THREE.Color: Unknown color `+e):this.setHex(n,t),this}clone(){return new this.constructor(this.r,this.g,this.b)}copy(e){return this.r=e.r,this.g=e.g,this.b=e.b,this}copySRGBToLinear(e){return this.r=kt(e.r),this.g=kt(e.g),this.b=kt(e.b),this}copyLinearToSRGB(e){return this.r=At(e.r),this.g=At(e.g),this.b=At(e.b),this}convertSRGBToLinear(){return this.copySRGBToLinear(this),this}convertLinearToSRGB(){return this.copyLinearToSRGB(this),this}getHex(e=Re){return Ot.fromWorkingColorSpace(mr.copy(this),e),Math.round(Ze(mr.r*255,0,255))*65536+Math.round(Ze(mr.g*255,0,255))*256+Math.round(Ze(mr.b*255,0,255))}getHexString(e=Re){return(`000000`+this.getHex(e).toString(16)).slice(-6)}getHSL(e,t=Ot.workingColorSpace){Ot.fromWorkingColorSpace(mr.copy(this),t);let n=mr.r,r=mr.g,i=mr.b,a=Math.max(n,r,i),o=Math.min(n,r,i),s,c,l=(o+a)/2;if(o===a)s=0,c=0;else{let e=a-o;switch(c=l<=.5?e/(a+o):e/(2-a-o),a){case n:s=(r-i)/e+(r<i?6:0);break;case r:s=(i-n)/e+2;break;case i:s=(n-r)/e+4}s/=6}return e.h=s,e.s=c,e.l=l,e}getRGB(e,t=Ot.workingColorSpace){return Ot.fromWorkingColorSpace(mr.copy(this),t),e.r=mr.r,e.g=mr.g,e.b=mr.b,e}getStyle(e=Re){Ot.fromWorkingColorSpace(mr.copy(this),e);let t=mr.r,n=mr.g,r=mr.b;return e===`srgb`?`rgb(${Math.round(t*255)},${Math.round(n*255)},${Math.round(r*255)})`:`color(${e} ${t.toFixed(3)} ${n.toFixed(3)} ${r.toFixed(3)})`}offsetHSL(e,t,n){return this.getHSL(dr),this.setHSL(dr.h+e,dr.s+t,dr.l+n)}add(e){return this.r+=e.r,this.g+=e.g,this.b+=e.b,this}addColors(e,t){return this.r=e.r+t.r,this.g=e.g+t.g,this.b=e.b+t.b,this}addScalar(e){return this.r+=e,this.g+=e,this.b+=e,this}sub(e){return this.r=Math.max(0,this.r-e.r),this.g=Math.max(0,this.g-e.g),this.b=Math.max(0,this.b-e.b),this}multiply(e){return this.r*=e.r,this.g*=e.g,this.b*=e.b,this}multiplyScalar(e){return this.r*=e,this.g*=e,this.b*=e,this}lerp(e,t){return this.r+=(e.r-this.r)*t,this.g+=(e.g-this.g)*t,this.b+=(e.b-this.b)*t,this}lerpColors(e,t,n){return this.r=e.r+(t.r-e.r)*n,this.g=e.g+(t.g-e.g)*n,this.b=e.b+(t.b-e.b)*n,this}lerpHSL(e,t){this.getHSL(dr),e.getHSL(fr);let n=tt(dr.h,fr.h,t),r=tt(dr.s,fr.s,t),i=tt(dr.l,fr.l,t);return this.setHSL(n,r,i),this}setFromVector3(e){return this.r=e.x,this.g=e.y,this.b=e.z,this}applyMatrix3(e){let t=this.r,n=this.g,r=this.b,i=e.elements;return this.r=i[0]*t+i[3]*n+i[6]*r,this.g=i[1]*t+i[4]*n+i[7]*r,this.b=i[2]*t+i[5]*n+i[8]*r,this}equals(e){return e.r===this.r&&e.g===this.g&&e.b===this.b}fromArray(e,t=0){return this.r=e[t],this.g=e[t+1],this.b=e[t+2],this}toArray(e=[],t=0){return e[t]=this.r,e[t+1]=this.g,e[t+2]=this.b,e}fromBufferAttribute(e,t){return this.r=e.getX(t),this.g=e.getY(t),this.b=e.getZ(t),this}toJSON(){return this.getHex()}*[Symbol.iterator](){yield this.r,yield this.g,yield this.b}},mr=new W;W.NAMES=ur;var hr=0,gr=class extends Ge{static get type(){return`Material`}get type(){return this.constructor.type}set type(e){}constructor(){super(),this.isMaterial=!0,Object.defineProperty(this,"id",{value:hr++}),this.uuid=Xe(),this.name=``,this.blending=1,this.side=0,this.vertexColors=!1,this.opacity=1,this.transparent=!1,this.alphaHash=!1,this.blendSrc=204,this.blendDst=205,this.blendEquation=100,this.blendSrcAlpha=null,this.blendDstAlpha=null,this.blendEquationAlpha=null,this.blendColor=new W(0,0,0),this.blendAlpha=0,this.depthFunc=3,this.depthTest=!0,this.depthWrite=!0,this.stencilWriteMask=255,this.stencilFunc=519,this.stencilRef=0,this.stencilFuncMask=255,this.stencilFail=He,this.stencilZFail=He,this.stencilZPass=He,this.stencilWrite=!1,this.clippingPlanes=null,this.clipIntersection=!1,this.clipShadows=!1,this.shadowSide=null,this.colorWrite=!0,this.precision=null,this.polygonOffset=!1,this.polygonOffsetFactor=0,this.polygonOffsetUnits=0,this.dithering=!1,this.alphaToCoverage=!1,this.premultipliedAlpha=!1,this.forceSinglePass=!1,this.visible=!0,this.toneMapped=!0,this.userData={},this.version=0,this._alphaTest=0}get alphaTest(){return this._alphaTest}set alphaTest(e){this._alphaTest>0!=e>0&&this.version++,this._alphaTest=e}onBeforeRender(){}onBeforeCompile(){}customProgramCacheKey(){return this.onBeforeCompile.toString()}setValues(e){if(e!==void 0)for(let t in e){let n=e[t];if(n===void 0){console.warn(`THREE.Material: parameter '${t}' has value of undefined.`);continue}let r=this[t];if(r===void 0){console.warn(`THREE.Material: '${t}' is not a property of THREE.${this.type}.`);continue}r&&r.isColor?r.set(n):r&&r.isVector3&&n&&n.isVector3?r.copy(n):this[t]=n}}toJSON(e){let t=e===void 0||typeof e==`string`;t&&(e={textures:{},images:{}});let n={metadata:{version:4.6,type:`Material`,generator:`Material.toJSON`}};n.uuid=this.uuid,n.type=this.type,this.name!==``&&(n.name=this.name),this.color&&this.color.isColor&&(n.color=this.color.getHex()),this.roughness!==void 0&&(n.roughness=this.roughness),this.metalness!==void 0&&(n.metalness=this.metalness),this.sheen!==void 0&&(n.sheen=this.sheen),this.sheenColor&&this.sheenColor.isColor&&(n.sheenColor=this.sheenColor.getHex()),this.sheenRoughness!==void 0&&(n.sheenRoughness=this.sheenRoughness),this.emissive&&this.emissive.isColor&&(n.emissive=this.emissive.getHex()),this.emissiveIntensity!==void 0&&this.emissiveIntensity!==1&&(n.emissiveIntensity=this.emissiveIntensity),this.specular&&this.specular.isColor&&(n.specular=this.specular.getHex()),this.specularIntensity!==void 0&&(n.specularIntensity=this.specularIntensity),this.specularColor&&this.specularColor.isColor&&(n.specularColor=this.specularColor.getHex()),this.shininess!==void 0&&(n.shininess=this.shininess),this.clearcoat!==void 0&&(n.clearcoat=this.clearcoat),this.clearcoatRoughness!==void 0&&(n.clearcoatRoughness=this.clearcoatRoughness),this.clearcoatMap&&this.clearcoatMap.isTexture&&(n.clearcoatMap=this.clearcoatMap.toJSON(e).uuid),this.clearcoatRoughnessMap&&this.clearcoatRoughnessMap.isTexture&&(n.clearcoatRoughnessMap=this.clearcoatRoughnessMap.toJSON(e).uuid),this.clearcoatNormalMap&&this.clearcoatNormalMap.isTexture&&(n.clearcoatNormalMap=this.clearcoatNormalMap.toJSON(e).uuid,n.clearcoatNormalScale=this.clearcoatNormalScale.toArray()),this.dispersion!==void 0&&(n.dispersion=this.dispersion),this.iridescence!==void 0&&(n.iridescence=this.iridescence),this.iridescenceIOR!==void 0&&(n.iridescenceIOR=this.iridescenceIOR),this.iridescenceThicknessRange!==void 0&&(n.iridescenceThicknessRange=this.iridescenceThicknessRange),this.iridescenceMap&&this.iridescenceMap.isTexture&&(n.iridescenceMap=this.iridescenceMap.toJSON(e).uuid),this.iridescenceThicknessMap&&this.iridescenceThicknessMap.isTexture&&(n.iridescenceThicknessMap=this.iridescenceThicknessMap.toJSON(e).uuid),this.anisotropy!==void 0&&(n.anisotropy=this.anisotropy),this.anisotropyRotation!==void 0&&(n.anisotropyRotation=this.anisotropyRotation),this.anisotropyMap&&this.anisotropyMap.isTexture&&(n.anisotropyMap=this.anisotropyMap.toJSON(e).uuid),this.map&&this.map.isTexture&&(n.map=this.map.toJSON(e).uuid),this.matcap&&this.matcap.isTexture&&(n.matcap=this.matcap.toJSON(e).uuid),this.alphaMap&&this.alphaMap.isTexture&&(n.alphaMap=this.alphaMap.toJSON(e).uuid),this.lightMap&&this.lightMap.isTexture&&(n.lightMap=this.lightMap.toJSON(e).uuid,n.lightMapIntensity=this.lightMapIntensity),this.aoMap&&this.aoMap.isTexture&&(n.aoMap=this.aoMap.toJSON(e).uuid,n.aoMapIntensity=this.aoMapIntensity),this.bumpMap&&this.bumpMap.isTexture&&(n.bumpMap=this.bumpMap.toJSON(e).uuid,n.bumpScale=this.bumpScale),this.normalMap&&this.normalMap.isTexture&&(n.normalMap=this.normalMap.toJSON(e).uuid,n.normalMapType=this.normalMapType,n.normalScale=this.normalScale.toArray()),this.displacementMap&&this.displacementMap.isTexture&&(n.displacementMap=this.displacementMap.toJSON(e).uuid,n.displacementScale=this.displacementScale,n.displacementBias=this.displacementBias),this.roughnessMap&&this.roughnessMap.isTexture&&(n.roughnessMap=this.roughnessMap.toJSON(e).uuid),this.metalnessMap&&this.metalnessMap.isTexture&&(n.metalnessMap=this.metalnessMap.toJSON(e).uuid),this.emissiveMap&&this.emissiveMap.isTexture&&(n.emissiveMap=this.emissiveMap.toJSON(e).uuid),this.specularMap&&this.specularMap.isTexture&&(n.specularMap=this.specularMap.toJSON(e).uuid),this.specularIntensityMap&&this.specularIntensityMap.isTexture&&(n.specularIntensityMap=this.specularIntensityMap.toJSON(e).uuid),this.specularColorMap&&this.specularColorMap.isTexture&&(n.specularColorMap=this.specularColorMap.toJSON(e).uuid),this.envMap&&this.envMap.isTexture&&(n.envMap=this.envMap.toJSON(e).uuid,this.combine!==void 0&&(n.combine=this.combine)),this.envMapRotation!==void 0&&(n.envMapRotation=this.envMapRotation.toArray()),this.envMapIntensity!==void 0&&(n.envMapIntensity=this.envMapIntensity),this.reflectivity!==void 0&&(n.reflectivity=this.reflectivity),this.refractionRatio!==void 0&&(n.refractionRatio=this.refractionRatio),this.gradientMap&&this.gradientMap.isTexture&&(n.gradientMap=this.gradientMap.toJSON(e).uuid),this.transmission!==void 0&&(n.transmission=this.transmission),this.transmissionMap&&this.transmissionMap.isTexture&&(n.transmissionMap=this.transmissionMap.toJSON(e).uuid),this.thickness!==void 0&&(n.thickness=this.thickness),this.thicknessMap&&this.thicknessMap.isTexture&&(n.thicknessMap=this.thicknessMap.toJSON(e).uuid),this.attenuationDistance!==void 0&&this.attenuationDistance!==1/0&&(n.attenuationDistance=this.attenuationDistance),this.attenuationColor!==void 0&&(n.attenuationColor=this.attenuationColor.getHex()),this.size!==void 0&&(n.size=this.size),this.shadowSide!==null&&(n.shadowSide=this.shadowSide),this.sizeAttenuation!==void 0&&(n.sizeAttenuation=this.sizeAttenuation),this.blending!==1&&(n.blending=this.blending),this.side!==0&&(n.side=this.side),this.vertexColors===!0&&(n.vertexColors=!0),this.opacity<1&&(n.opacity=this.opacity),this.transparent===!0&&(n.transparent=!0),this.blendSrc!==204&&(n.blendSrc=this.blendSrc),this.blendDst!==205&&(n.blendDst=this.blendDst),this.blendEquation!==100&&(n.blendEquation=this.blendEquation),this.blendSrcAlpha!==null&&(n.blendSrcAlpha=this.blendSrcAlpha),this.blendDstAlpha!==null&&(n.blendDstAlpha=this.blendDstAlpha),this.blendEquationAlpha!==null&&(n.blendEquationAlpha=this.blendEquationAlpha),this.blendColor&&this.blendColor.isColor&&(n.blendColor=this.blendColor.getHex()),this.blendAlpha!==0&&(n.blendAlpha=this.blendAlpha),this.depthFunc!==3&&(n.depthFunc=this.depthFunc),this.depthTest===!1&&(n.depthTest=this.depthTest),this.depthWrite===!1&&(n.depthWrite=this.depthWrite),this.colorWrite===!1&&(n.colorWrite=this.colorWrite),this.stencilWriteMask!==255&&(n.stencilWriteMask=this.stencilWriteMask),this.stencilFunc!==519&&(n.stencilFunc=this.stencilFunc),this.stencilRef!==0&&(n.stencilRef=this.stencilRef),this.stencilFuncMask!==255&&(n.stencilFuncMask=this.stencilFuncMask),this.stencilFail!==7680&&(n.stencilFail=this.stencilFail),this.stencilZFail!==7680&&(n.stencilZFail=this.stencilZFail),this.stencilZPass!==7680&&(n.stencilZPass=this.stencilZPass),this.stencilWrite===!0&&(n.stencilWrite=this.stencilWrite),this.rotation!==void 0&&this.rotation!==0&&(n.rotation=this.rotation),this.polygonOffset===!0&&(n.polygonOffset=!0),this.polygonOffsetFactor!==0&&(n.polygonOffsetFactor=this.polygonOffsetFactor),this.polygonOffsetUnits!==0&&(n.polygonOffsetUnits=this.polygonOffsetUnits),this.linewidth!==void 0&&this.linewidth!==1&&(n.linewidth=this.linewidth),this.dashSize!==void 0&&(n.dashSize=this.dashSize),this.gapSize!==void 0&&(n.gapSize=this.gapSize),this.scale!==void 0&&(n.scale=this.scale),this.dithering===!0&&(n.dithering=!0),this.alphaTest>0&&(n.alphaTest=this.alphaTest),this.alphaHash===!0&&(n.alphaHash=!0),this.alphaToCoverage===!0&&(n.alphaToCoverage=!0),this.premultipliedAlpha===!0&&(n.premultipliedAlpha=!0),this.forceSinglePass===!0&&(n.forceSinglePass=!0),this.wireframe===!0&&(n.wireframe=!0),this.wireframeLinewidth>1&&(n.wireframeLinewidth=this.wireframeLinewidth),this.wireframeLinecap!==`round`&&(n.wireframeLinecap=this.wireframeLinecap),this.wireframeLinejoin!==`round`&&(n.wireframeLinejoin=this.wireframeLinejoin),this.flatShading===!0&&(n.flatShading=!0),this.visible===!1&&(n.visible=!1),this.toneMapped===!1&&(n.toneMapped=!1),this.fog===!1&&(n.fog=!1),Object.keys(this.userData).length>0&&(n.userData=this.userData);function r(e){let t=[];for(let n in e){let r=e[n];delete r.metadata,t.push(r)}return t}if(t){let t=r(e.textures),i=r(e.images);t.length>0&&(n.textures=t),i.length>0&&(n.images=i)}return n}clone(){return new this.constructor().copy(this)}copy(e){this.name=e.name,this.blending=e.blending,this.side=e.side,this.vertexColors=e.vertexColors,this.opacity=e.opacity,this.transparent=e.transparent,this.blendSrc=e.blendSrc,this.blendDst=e.blendDst,this.blendEquation=e.blendEquation,this.blendSrcAlpha=e.blendSrcAlpha,this.blendDstAlpha=e.blendDstAlpha,this.blendEquationAlpha=e.blendEquationAlpha,this.blendColor.copy(e.blendColor),this.blendAlpha=e.blendAlpha,this.depthFunc=e.depthFunc,this.depthTest=e.depthTest,this.depthWrite=e.depthWrite,this.stencilWriteMask=e.stencilWriteMask,this.stencilFunc=e.stencilFunc,this.stencilRef=e.stencilRef,this.stencilFuncMask=e.stencilFuncMask,this.stencilFail=e.stencilFail,this.stencilZFail=e.stencilZFail,this.stencilZPass=e.stencilZPass,this.stencilWrite=e.stencilWrite;let t=e.clippingPlanes,n=null;if(t!==null){let e=t.length;n=Array(e);for(let r=0;r!==e;++r)n[r]=t[r].clone()}return this.clippingPlanes=n,this.clipIntersection=e.clipIntersection,this.clipShadows=e.clipShadows,this.shadowSide=e.shadowSide,this.colorWrite=e.colorWrite,this.precision=e.precision,this.polygonOffset=e.polygonOffset,this.polygonOffsetFactor=e.polygonOffsetFactor,this.polygonOffsetUnits=e.polygonOffsetUnits,this.dithering=e.dithering,this.alphaTest=e.alphaTest,this.alphaHash=e.alphaHash,this.alphaToCoverage=e.alphaToCoverage,this.premultipliedAlpha=e.premultipliedAlpha,this.forceSinglePass=e.forceSinglePass,this.visible=e.visible,this.toneMapped=e.toneMapped,this.userData=JSON.parse(JSON.stringify(e.userData)),this}dispose(){this.dispatchEvent({type:`dispose`})}set needsUpdate(e){e===!0&&this.version++}onBuild(){console.warn(`Material: onBuild() has been removed.`)}},_r=class extends gr{static get type(){return`MeshBasicMaterial`}constructor(e){super(),this.isMeshBasicMaterial=!0,this.color=new W(16777215),this.map=null,this.lightMap=null,this.lightMapIntensity=1,this.aoMap=null,this.aoMapIntensity=1,this.specularMap=null,this.alphaMap=null,this.envMap=null,this.envMapRotation=new Mn,this.combine=0,this.reflectivity=1,this.refractionRatio=.98,this.wireframe=!1,this.wireframeLinewidth=1,this.wireframeLinecap=`round`,this.wireframeLinejoin=`round`,this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.lightMap=e.lightMap,this.lightMapIntensity=e.lightMapIntensity,this.aoMap=e.aoMap,this.aoMapIntensity=e.aoMapIntensity,this.specularMap=e.specularMap,this.alphaMap=e.alphaMap,this.envMap=e.envMap,this.envMapRotation.copy(e.envMapRotation),this.combine=e.combine,this.reflectivity=e.reflectivity,this.refractionRatio=e.refractionRatio,this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this.wireframeLinecap=e.wireframeLinecap,this.wireframeLinejoin=e.wireframeLinejoin,this.fog=e.fog,this}},vr=new H,yr=new R,br=class{constructor(e,t,n=!1){if(Array.isArray(e))throw TypeError(`THREE.BufferAttribute: array should be a Typed Array.`);this.isBufferAttribute=!0,this.name=``,this.array=e,this.itemSize=t,this.count=e===void 0?0:e.length/t,this.normalized=n,this.usage=Ue,this.updateRanges=[],this.gpuType=v,this.version=0}onUploadCallback(){}set needsUpdate(e){e===!0&&this.version++}setUsage(e){return this.usage=e,this}addUpdateRange(e,t){this.updateRanges.push({start:e,count:t})}clearUpdateRanges(){this.updateRanges.length=0}copy(e){return this.name=e.name,this.array=new e.array.constructor(e.array),this.itemSize=e.itemSize,this.count=e.count,this.normalized=e.normalized,this.usage=e.usage,this.gpuType=e.gpuType,this}copyAt(e,t,n){e*=this.itemSize,n*=t.itemSize;for(let r=0,i=this.itemSize;r<i;r++)this.array[e+r]=t.array[n+r];return this}copyArray(e){return this.array.set(e),this}applyMatrix3(e){if(this.itemSize===2)for(let t=0,n=this.count;t<n;t++)yr.fromBufferAttribute(this,t),yr.applyMatrix3(e),this.setXY(t,yr.x,yr.y);else if(this.itemSize===3)for(let t=0,n=this.count;t<n;t++)vr.fromBufferAttribute(this,t),vr.applyMatrix3(e),this.setXYZ(t,vr.x,vr.y,vr.z);return this}applyMatrix4(e){for(let t=0,n=this.count;t<n;t++)vr.fromBufferAttribute(this,t),vr.applyMatrix4(e),this.setXYZ(t,vr.x,vr.y,vr.z);return this}applyNormalMatrix(e){for(let t=0,n=this.count;t<n;t++)vr.fromBufferAttribute(this,t),vr.applyNormalMatrix(e),this.setXYZ(t,vr.x,vr.y,vr.z);return this}transformDirection(e){for(let t=0,n=this.count;t<n;t++)vr.fromBufferAttribute(this,t),vr.transformDirection(e),this.setXYZ(t,vr.x,vr.y,vr.z);return this}set(e,t=0){return this.array.set(e,t),this}getComponent(e,t){let n=this.array[e*this.itemSize+t];return this.normalized&&(n=gt(n,this.array)),n}setComponent(e,t,n){return this.normalized&&(n=_t(n,this.array)),this.array[e*this.itemSize+t]=n,this}getX(e){let t=this.array[e*this.itemSize];return this.normalized&&(t=gt(t,this.array)),t}setX(e,t){return this.normalized&&(t=_t(t,this.array)),this.array[e*this.itemSize]=t,this}getY(e){let t=this.array[e*this.itemSize+1];return this.normalized&&(t=gt(t,this.array)),t}setY(e,t){return this.normalized&&(t=_t(t,this.array)),this.array[e*this.itemSize+1]=t,this}getZ(e){let t=this.array[e*this.itemSize+2];return this.normalized&&(t=gt(t,this.array)),t}setZ(e,t){return this.normalized&&(t=_t(t,this.array)),this.array[e*this.itemSize+2]=t,this}getW(e){let t=this.array[e*this.itemSize+3];return this.normalized&&(t=gt(t,this.array)),t}setW(e,t){return this.normalized&&(t=_t(t,this.array)),this.array[e*this.itemSize+3]=t,this}setXY(e,t,n){return e*=this.itemSize,this.normalized&&(t=_t(t,this.array),n=_t(n,this.array)),this.array[e+0]=t,this.array[e+1]=n,this}setXYZ(e,t,n,r){return e*=this.itemSize,this.normalized&&(t=_t(t,this.array),n=_t(n,this.array),r=_t(r,this.array)),this.array[e+0]=t,this.array[e+1]=n,this.array[e+2]=r,this}setXYZW(e,t,n,r,i){return e*=this.itemSize,this.normalized&&(t=_t(t,this.array),n=_t(n,this.array),r=_t(r,this.array),i=_t(i,this.array)),this.array[e+0]=t,this.array[e+1]=n,this.array[e+2]=r,this.array[e+3]=i,this}onUpload(e){return this.onUploadCallback=e,this}clone(){return new this.constructor(this.array,this.itemSize).copy(this)}toJSON(){let e={itemSize:this.itemSize,type:this.array.constructor.name,array:Array.from(this.array),normalized:this.normalized};return this.name!==``&&(e.name=this.name),this.usage!==35044&&(e.usage=this.usage),e}},xr=class extends br{constructor(e,t,n){super(new Uint16Array(e),t,n)}},Sr=class extends br{constructor(e,t,n){super(new Uint32Array(e),t,n)}},Cr=class extends br{constructor(e,t,n){super(new Float32Array(e),t,n)}},wr=0,Tr=new U,Er=new Yn,Dr=new H,Or=new Yt,kr=new Yt,Ar=new H,jr=class e extends Ge{constructor(){super(),this.isBufferGeometry=!0,Object.defineProperty(this,"id",{value:wr++}),this.uuid=Xe(),this.name=``,this.type=`BufferGeometry`,this.index=null,this.indirect=null,this.attributes={},this.morphAttributes={},this.morphTargetsRelative=!1,this.groups=[],this.boundingBox=null,this.boundingSphere=null,this.drawRange={start:0,count:1/0},this.userData={}}getIndex(){return this.index}setIndex(e){return this.index=Array.isArray(e)?new(bt(e)?Sr:xr)(e,1):e,this}setIndirect(e){return this.indirect=e,this}getIndirect(){return this.indirect}getAttribute(e){return this.attributes[e]}setAttribute(e,t){return this.attributes[e]=t,this}deleteAttribute(e){return delete this.attributes[e],this}hasAttribute(e){return this.attributes[e]!==void 0}addGroup(e,t,n=0){this.groups.push({start:e,count:t,materialIndex:n})}clearGroups(){this.groups=[]}setDrawRange(e,t){this.drawRange.start=e,this.drawRange.count=t}applyMatrix4(e){let t=this.attributes.position;t!==void 0&&(t.applyMatrix4(e),t.needsUpdate=!0);let n=this.attributes.normal;if(n!==void 0){let t=new z().getNormalMatrix(e);n.applyNormalMatrix(t),n.needsUpdate=!0}let r=this.attributes.tangent;return r!==void 0&&(r.transformDirection(e),r.needsUpdate=!0),this.boundingBox!==null&&this.computeBoundingBox(),this.boundingSphere!==null&&this.computeBoundingSphere(),this}applyQuaternion(e){return Tr.makeRotationFromQuaternion(e),this.applyMatrix4(Tr),this}rotateX(e){return Tr.makeRotationX(e),this.applyMatrix4(Tr),this}rotateY(e){return Tr.makeRotationY(e),this.applyMatrix4(Tr),this}rotateZ(e){return Tr.makeRotationZ(e),this.applyMatrix4(Tr),this}translate(e,t,n){return Tr.makeTranslation(e,t,n),this.applyMatrix4(Tr),this}scale(e,t,n){return Tr.makeScale(e,t,n),this.applyMatrix4(Tr),this}lookAt(e){return Er.lookAt(e),Er.updateMatrix(),this.applyMatrix4(Er.matrix),this}center(){return this.computeBoundingBox(),this.boundingBox.getCenter(Dr).negate(),this.translate(Dr.x,Dr.y,Dr.z),this}setFromPoints(e){let t=this.getAttribute(`position`);if(t===void 0){let t=[];for(let n=0,r=e.length;n<r;n++){let r=e[n];t.push(r.x,r.y,r.z||0)}this.setAttribute(`position`,new Cr(t,3))}else{for(let n=0,r=t.count;n<r;n++){let r=e[n];t.setXYZ(n,r.x,r.y,r.z||0)}e.length>t.count&&console.warn(`THREE.BufferGeometry: Buffer size too small for points data. Use .dispose() and create a new geometry.`),t.needsUpdate=!0}return this}computeBoundingBox(){this.boundingBox===null&&(this.boundingBox=new Yt);let e=this.attributes.position,t=this.morphAttributes.position;if(e&&e.isGLBufferAttribute){console.error(`THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.`,this),this.boundingBox.set(new H(-1/0,-1/0,-1/0),new H(1/0,1/0,1/0));return}if(e!==void 0){if(this.boundingBox.setFromBufferAttribute(e),t)for(let e=0,n=t.length;e<n;e++){let n=t[e];Or.setFromBufferAttribute(n),this.morphTargetsRelative?(Ar.addVectors(this.boundingBox.min,Or.min),this.boundingBox.expandByPoint(Ar),Ar.addVectors(this.boundingBox.max,Or.max),this.boundingBox.expandByPoint(Ar)):(this.boundingBox.expandByPoint(Or.min),this.boundingBox.expandByPoint(Or.max))}}else this.boundingBox.makeEmpty();(isNaN(this.boundingBox.min.x)||isNaN(this.boundingBox.min.y)||isNaN(this.boundingBox.min.z))&&console.error(`THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.`,this)}computeBoundingSphere(){this.boundingSphere===null&&(this.boundingSphere=new mn);let e=this.attributes.position,t=this.morphAttributes.position;if(e&&e.isGLBufferAttribute){console.error(`THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.`,this),this.boundingSphere.set(new H,1/0);return}if(e){let n=this.boundingSphere.center;if(Or.setFromBufferAttribute(e),t)for(let e=0,n=t.length;e<n;e++){let n=t[e];kr.setFromBufferAttribute(n),this.morphTargetsRelative?(Ar.addVectors(Or.min,kr.min),Or.expandByPoint(Ar),Ar.addVectors(Or.max,kr.max),Or.expandByPoint(Ar)):(Or.expandByPoint(kr.min),Or.expandByPoint(kr.max))}Or.getCenter(n);let r=0;for(let t=0,i=e.count;t<i;t++)Ar.fromBufferAttribute(e,t),r=Math.max(r,n.distanceToSquared(Ar));if(t)for(let i=0,a=t.length;i<a;i++){let a=t[i],o=this.morphTargetsRelative;for(let t=0,i=a.count;t<i;t++)Ar.fromBufferAttribute(a,t),o&&(Dr.fromBufferAttribute(e,t),Ar.add(Dr)),r=Math.max(r,n.distanceToSquared(Ar))}this.boundingSphere.radius=Math.sqrt(r),isNaN(this.boundingSphere.radius)&&console.error(`THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.`,this)}}computeTangents(){let e=this.index,t=this.attributes;if(e===null||t.position===void 0||t.normal===void 0||t.uv===void 0){console.error(`THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)`);return}let n=t.position,r=t.normal,i=t.uv;this.hasAttribute(`tangent`)===!1&&this.setAttribute(`tangent`,new br(new Float32Array(4*n.count),4));let a=this.getAttribute(`tangent`),o=[],s=[];for(let e=0;e<n.count;e++)o[e]=new H,s[e]=new H;let c=new H,l=new H,u=new H,d=new R,f=new R,p=new R,m=new H,h=new H;function g(e,t,r){c.fromBufferAttribute(n,e),l.fromBufferAttribute(n,t),u.fromBufferAttribute(n,r),d.fromBufferAttribute(i,e),f.fromBufferAttribute(i,t),p.fromBufferAttribute(i,r),l.sub(c),u.sub(c),f.sub(d),p.sub(d);let a=1/(f.x*p.y-p.x*f.y);isFinite(a)&&(m.copy(l).multiplyScalar(p.y).addScaledVector(u,-f.y).multiplyScalar(a),h.copy(u).multiplyScalar(f.x).addScaledVector(l,-p.x).multiplyScalar(a),o[e].add(m),o[t].add(m),o[r].add(m),s[e].add(h),s[t].add(h),s[r].add(h))}let _=this.groups;_.length===0&&(_=[{start:0,count:e.count}]);for(let t=0,n=_.length;t<n;++t){let n=_[t],r=n.start,i=n.count;for(let t=r,n=r+i;t<n;t+=3)g(e.getX(t+0),e.getX(t+1),e.getX(t+2))}let v=new H,y=new H,b=new H,x=new H;function S(e){b.fromBufferAttribute(r,e),x.copy(b);let t=o[e];v.copy(t),v.sub(b.multiplyScalar(b.dot(t))).normalize(),y.crossVectors(x,t);let n=y.dot(s[e])<0?-1:1;a.setXYZW(e,v.x,v.y,v.z,n)}for(let t=0,n=_.length;t<n;++t){let n=_[t],r=n.start,i=n.count;for(let t=r,n=r+i;t<n;t+=3)S(e.getX(t+0)),S(e.getX(t+1)),S(e.getX(t+2))}}computeVertexNormals(){let e=this.index,t=this.getAttribute(`position`);if(t!==void 0){let n=this.getAttribute(`normal`);if(n===void 0)n=new br(new Float32Array(t.count*3),3),this.setAttribute(`normal`,n);else for(let e=0,t=n.count;e<t;e++)n.setXYZ(e,0,0,0);let r=new H,i=new H,a=new H,o=new H,s=new H,c=new H,l=new H,u=new H;if(e)for(let d=0,f=e.count;d<f;d+=3){let f=e.getX(d+0),p=e.getX(d+1),m=e.getX(d+2);r.fromBufferAttribute(t,f),i.fromBufferAttribute(t,p),a.fromBufferAttribute(t,m),l.subVectors(a,i),u.subVectors(r,i),l.cross(u),o.fromBufferAttribute(n,f),s.fromBufferAttribute(n,p),c.fromBufferAttribute(n,m),o.add(l),s.add(l),c.add(l),n.setXYZ(f,o.x,o.y,o.z),n.setXYZ(p,s.x,s.y,s.z),n.setXYZ(m,c.x,c.y,c.z)}else for(let e=0,o=t.count;e<o;e+=3)r.fromBufferAttribute(t,e+0),i.fromBufferAttribute(t,e+1),a.fromBufferAttribute(t,e+2),l.subVectors(a,i),u.subVectors(r,i),l.cross(u),n.setXYZ(e+0,l.x,l.y,l.z),n.setXYZ(e+1,l.x,l.y,l.z),n.setXYZ(e+2,l.x,l.y,l.z);this.normalizeNormals(),n.needsUpdate=!0}}normalizeNormals(){let e=this.attributes.normal;for(let t=0,n=e.count;t<n;t++)Ar.fromBufferAttribute(e,t),Ar.normalize(),e.setXYZ(t,Ar.x,Ar.y,Ar.z)}toNonIndexed(){function t(e,t){let n=e.array,r=e.itemSize,i=e.normalized,a=new n.constructor(t.length*r),o=0,s=0;for(let i=0,c=t.length;i<c;i++){o=e.isInterleavedBufferAttribute?t[i]*e.data.stride+e.offset:t[i]*r;for(let e=0;e<r;e++)a[s++]=n[o++]}return new br(a,r,i)}if(this.index===null)return console.warn(`THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.`),this;let n=new e,r=this.index.array,i=this.attributes;for(let e in i){let a=i[e],o=t(a,r);n.setAttribute(e,o)}let a=this.morphAttributes;for(let e in a){let i=[],o=a[e];for(let e=0,n=o.length;e<n;e++){let n=o[e],a=t(n,r);i.push(a)}n.morphAttributes[e]=i}n.morphTargetsRelative=this.morphTargetsRelative;let o=this.groups;for(let e=0,t=o.length;e<t;e++){let t=o[e];n.addGroup(t.start,t.count,t.materialIndex)}return n}toJSON(){let e={metadata:{version:4.6,type:`BufferGeometry`,generator:`BufferGeometry.toJSON`}};if(e.uuid=this.uuid,e.type=this.type,this.name!==``&&(e.name=this.name),Object.keys(this.userData).length>0&&(e.userData=this.userData),this.parameters!==void 0){let t=this.parameters;for(let n in t)t[n]!==void 0&&(e[n]=t[n]);return e}e.data={attributes:{}};let t=this.index;t!==null&&(e.data.index={type:t.array.constructor.name,array:Array.prototype.slice.call(t.array)});let n=this.attributes;for(let t in n){let r=n[t];e.data.attributes[t]=r.toJSON(e.data)}let r={},i=!1;for(let t in this.morphAttributes){let n=this.morphAttributes[t],a=[];for(let t=0,r=n.length;t<r;t++){let r=n[t];a.push(r.toJSON(e.data))}a.length>0&&(r[t]=a,i=!0)}i&&(e.data.morphAttributes=r,e.data.morphTargetsRelative=this.morphTargetsRelative);let a=this.groups;a.length>0&&(e.data.groups=JSON.parse(JSON.stringify(a)));let o=this.boundingSphere;return o!==null&&(e.data.boundingSphere={center:o.center.toArray(),radius:o.radius}),e}clone(){return new this.constructor().copy(this)}copy(e){this.index=null,this.attributes={},this.morphAttributes={},this.groups=[],this.boundingBox=null,this.boundingSphere=null;let t={};this.name=e.name;let n=e.index;n!==null&&this.setIndex(n.clone(t));let r=e.attributes;for(let e in r){let n=r[e];this.setAttribute(e,n.clone(t))}let i=e.morphAttributes;for(let e in i){let n=[],r=i[e];for(let e=0,i=r.length;e<i;e++)n.push(r[e].clone(t));this.morphAttributes[e]=n}this.morphTargetsRelative=e.morphTargetsRelative;let a=e.groups;for(let e=0,t=a.length;e<t;e++){let t=a[e];this.addGroup(t.start,t.count,t.materialIndex)}let o=e.boundingBox;o!==null&&(this.boundingBox=o.clone());let s=e.boundingSphere;return s!==null&&(this.boundingSphere=s.clone()),this.drawRange.start=e.drawRange.start,this.drawRange.count=e.drawRange.count,this.userData=e.userData,this}dispose(){this.dispatchEvent({type:`dispose`})}},Mr=new U,Nr=new Sn,Pr=new mn,Fr=new H,Ir=new H,Lr=new H,Rr=new H,zr=new H,Br=new H,Vr=new H,Hr=new H,Ur=class extends Yn{constructor(e=new jr,t=new _r){super(),this.isMesh=!0,this.type=`Mesh`,this.geometry=e,this.material=t,this.updateMorphTargets()}copy(e,t){return super.copy(e,t),e.morphTargetInfluences!==void 0&&(this.morphTargetInfluences=e.morphTargetInfluences.slice()),e.morphTargetDictionary!==void 0&&(this.morphTargetDictionary=Object.assign({},e.morphTargetDictionary)),this.material=Array.isArray(e.material)?e.material.slice():e.material,this.geometry=e.geometry,this}updateMorphTargets(){let e=this.geometry.morphAttributes,t=Object.keys(e);if(t.length>0){let n=e[t[0]];if(n!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let e=0,t=n.length;e<t;e++){let t=n[e].name||String(e);this.morphTargetInfluences.push(0),this.morphTargetDictionary[t]=e}}}}getVertexPosition(e,t){let n=this.geometry,r=n.attributes.position,i=n.morphAttributes.position,a=n.morphTargetsRelative;t.fromBufferAttribute(r,e);let o=this.morphTargetInfluences;if(i&&o){Br.set(0,0,0);for(let n=0,r=i.length;n<r;n++){let r=o[n],s=i[n];r!==0&&(zr.fromBufferAttribute(s,e),a?Br.addScaledVector(zr,r):Br.addScaledVector(zr.sub(t),r))}t.add(Br)}return t}raycast(e,t){let n=this.geometry,r=this.material,i=this.matrixWorld;r!==void 0&&(n.boundingSphere===null&&n.computeBoundingSphere(),Pr.copy(n.boundingSphere),Pr.applyMatrix4(i),Nr.copy(e.ray).recast(e.near),!(Pr.containsPoint(Nr.origin)===!1&&(Nr.intersectSphere(Pr,Fr)===null||Nr.origin.distanceToSquared(Fr)>(e.far-e.near)**2))&&(Mr.copy(i).invert(),Nr.copy(e.ray).applyMatrix4(Mr),(n.boundingBox===null||Nr.intersectsBox(n.boundingBox)!==!1)&&this._computeIntersections(e,t,Nr)))}_computeIntersections(e,t,n){let r,i=this.geometry,a=this.material,o=i.index,s=i.attributes.position,c=i.attributes.uv,l=i.attributes.uv1,u=i.attributes.normal,d=i.groups,f=i.drawRange;if(o!==null){if(Array.isArray(a))for(let i=0,s=d.length;i<s;i++){let s=d[i],p=a[s.materialIndex],m=Math.max(s.start,f.start),h=Math.min(o.count,Math.min(s.start+s.count,f.start+f.count));for(let i=m,a=h;i<a;i+=3){let a=o.getX(i),d=o.getX(i+1),f=o.getX(i+2);r=Gr(this,p,e,n,c,l,u,a,d,f),r&&(r.faceIndex=Math.floor(i/3),r.face.materialIndex=s.materialIndex,t.push(r))}}else{let i=Math.max(0,f.start),s=Math.min(o.count,f.start+f.count);for(let d=i,f=s;d<f;d+=3){let i=o.getX(d),s=o.getX(d+1),f=o.getX(d+2);r=Gr(this,a,e,n,c,l,u,i,s,f),r&&(r.faceIndex=Math.floor(d/3),t.push(r))}}}else if(s!==void 0){if(Array.isArray(a))for(let i=0,o=d.length;i<o;i++){let o=d[i],p=a[o.materialIndex],m=Math.max(o.start,f.start),h=Math.min(s.count,Math.min(o.start+o.count,f.start+f.count));for(let i=m,a=h;i<a;i+=3){let a=i,s=i+1,d=i+2;r=Gr(this,p,e,n,c,l,u,a,s,d),r&&(r.faceIndex=Math.floor(i/3),r.face.materialIndex=o.materialIndex,t.push(r))}}else{let i=Math.max(0,f.start),o=Math.min(s.count,f.start+f.count);for(let s=i,d=o;s<d;s+=3){let i=s,o=s+1,d=s+2;r=Gr(this,a,e,n,c,l,u,i,o,d),r&&(r.faceIndex=Math.floor(s/3),t.push(r))}}}}};function Wr(e,t,n,r,i,a,o,s){let c;if(c=t.side===1?r.intersectTriangle(o,a,i,!0,s):r.intersectTriangle(i,a,o,t.side===0,s),c===null)return null;Hr.copy(s),Hr.applyMatrix4(e.matrixWorld);let l=n.ray.origin.distanceTo(Hr);return l<n.near||l>n.far?null:{distance:l,point:Hr.clone(),object:e}}function Gr(e,t,n,r,i,a,o,s,c,l){e.getVertexPosition(s,Ir),e.getVertexPosition(c,Lr),e.getVertexPosition(l,Rr);let u=Wr(e,t,n,r,Ir,Lr,Rr,Vr);if(u){let e=new H;lr.getBarycoord(Vr,Ir,Lr,Rr,e),i&&(u.uv=lr.getInterpolatedAttribute(i,s,c,l,e,new R)),a&&(u.uv1=lr.getInterpolatedAttribute(a,s,c,l,e,new R)),o&&(u.normal=lr.getInterpolatedAttribute(o,s,c,l,e,new H),u.normal.dot(r.direction)>0&&u.normal.multiplyScalar(-1));let t={a:s,b:c,c:l,normal:new H,materialIndex:0};lr.getNormal(Ir,Lr,Rr,t.normal),u.face=t,u.barycoord=e}return u}var Kr=class e extends jr{constructor(e=1,t=1,n=1,r=1,i=1,a=1){super(),this.type=`BoxGeometry`,this.parameters={width:e,height:t,depth:n,widthSegments:r,heightSegments:i,depthSegments:a};let o=this;r=Math.floor(r),i=Math.floor(i),a=Math.floor(a);let s=[],c=[],l=[],u=[],d=0,f=0;p(`z`,`y`,`x`,-1,-1,n,t,e,a,i,0),p(`z`,`y`,`x`,1,-1,n,t,-e,a,i,1),p(`x`,`z`,`y`,1,1,e,n,t,r,a,2),p(`x`,`z`,`y`,1,-1,e,n,-t,r,a,3),p(`x`,`y`,`z`,1,-1,e,t,n,r,i,4),p(`x`,`y`,`z`,-1,-1,e,t,-n,r,i,5),this.setIndex(s),this.setAttribute(`position`,new Cr(c,3)),this.setAttribute(`normal`,new Cr(l,3)),this.setAttribute(`uv`,new Cr(u,2));function p(e,t,n,r,i,a,p,m,h,g,_){let v=a/h,y=p/g,b=a/2,x=p/2,S=m/2,C=h+1,w=g+1,T=0,E=0,D=new H;for(let a=0;a<w;a++){let o=a*y-x;for(let s=0;s<C;s++)D[e]=(s*v-b)*r,D[t]=o*i,D[n]=S,c.push(D.x,D.y,D.z),D[e]=0,D[t]=0,D[n]=m>0?1:-1,l.push(D.x,D.y,D.z),u.push(s/h),u.push(1-a/g),T+=1}for(let e=0;e<g;e++)for(let t=0;t<h;t++){let n=d+t+C*e,r=d+t+C*(e+1),i=d+(t+1)+C*(e+1),a=d+(t+1)+C*e;s.push(n,r,a),s.push(r,i,a),E+=6}o.addGroup(f,E,_),f+=E,d+=T}}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(t){return new e(t.width,t.height,t.depth,t.widthSegments,t.heightSegments,t.depthSegments)}};function qr(e){let t={};for(let n in e){t[n]={};for(let r in e[n]){let i=e[n][r];i&&(i.isColor||i.isMatrix3||i.isMatrix4||i.isVector2||i.isVector3||i.isVector4||i.isTexture||i.isQuaternion)?i.isRenderTargetTexture?(console.warn(`UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms().`),t[n][r]=null):t[n][r]=i.clone():Array.isArray(i)?t[n][r]=i.slice():t[n][r]=i}}return t}function Jr(e){let t={};for(let n=0;n<e.length;n++){let r=qr(e[n]);for(let e in r)t[e]=r[e]}return t}function Yr(e){let t=[];for(let n=0;n<e.length;n++)t.push(e[n].clone());return t}function Xr(e){let t=e.getRenderTarget();return t===null?e.outputColorSpace:t.isXRRenderTarget===!0?t.texture.colorSpace:Ot.workingColorSpace}var Zr={clone:qr,merge:Jr},Qr=`void main() {
	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}`,$r=`void main() {
	gl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
}`,ei=class extends gr{static get type(){return`ShaderMaterial`}constructor(e){super(),this.isShaderMaterial=!0,this.defines={},this.uniforms={},this.uniformsGroups=[],this.vertexShader=Qr,this.fragmentShader=$r,this.linewidth=1,this.wireframe=!1,this.wireframeLinewidth=1,this.fog=!1,this.lights=!1,this.clipping=!1,this.forceSinglePass=!0,this.extensions={clipCullDistance:!1,multiDraw:!1},this.defaultAttributeValues={color:[1,1,1],uv:[0,0],uv1:[0,0]},this.index0AttributeName=void 0,this.uniformsNeedUpdate=!1,this.glslVersion=null,e!==void 0&&this.setValues(e)}copy(e){return super.copy(e),this.fragmentShader=e.fragmentShader,this.vertexShader=e.vertexShader,this.uniforms=qr(e.uniforms),this.uniformsGroups=Yr(e.uniformsGroups),this.defines=Object.assign({},e.defines),this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this.fog=e.fog,this.lights=e.lights,this.clipping=e.clipping,this.extensions=Object.assign({},e.extensions),this.glslVersion=e.glslVersion,this}toJSON(e){let t=super.toJSON(e);t.glslVersion=this.glslVersion,t.uniforms={};for(let n in this.uniforms){let r=this.uniforms[n].value;r&&r.isTexture?t.uniforms[n]={type:`t`,value:r.toJSON(e).uuid}:r&&r.isColor?t.uniforms[n]={type:`c`,value:r.getHex()}:r&&r.isVector2?t.uniforms[n]={type:`v2`,value:r.toArray()}:r&&r.isVector3?t.uniforms[n]={type:`v3`,value:r.toArray()}:r&&r.isVector4?t.uniforms[n]={type:`v4`,value:r.toArray()}:r&&r.isMatrix3?t.uniforms[n]={type:`m3`,value:r.toArray()}:r&&r.isMatrix4?t.uniforms[n]={type:`m4`,value:r.toArray()}:t.uniforms[n]={value:r}}Object.keys(this.defines).length>0&&(t.defines=this.defines),t.vertexShader=this.vertexShader,t.fragmentShader=this.fragmentShader,t.lights=this.lights,t.clipping=this.clipping;let n={};for(let e in this.extensions)this.extensions[e]===!0&&(n[e]=!0);return Object.keys(n).length>0&&(t.extensions=n),t}},ti=class extends Yn{constructor(){super(),this.isCamera=!0,this.type=`Camera`,this.matrixWorldInverse=new U,this.projectionMatrix=new U,this.projectionMatrixInverse=new U,this.coordinateSystem=We}copy(e,t){return super.copy(e,t),this.matrixWorldInverse.copy(e.matrixWorldInverse),this.projectionMatrix.copy(e.projectionMatrix),this.projectionMatrixInverse.copy(e.projectionMatrixInverse),this.coordinateSystem=e.coordinateSystem,this}getWorldDirection(e){return super.getWorldDirection(e).negate()}updateMatrixWorld(e){super.updateMatrixWorld(e),this.matrixWorldInverse.copy(this.matrixWorld).invert()}updateWorldMatrix(e,t){super.updateWorldMatrix(e,t),this.matrixWorldInverse.copy(this.matrixWorld).invert()}clone(){return new this.constructor().copy(this)}},ni=new H,ri=new R,ii=new R,ai=class extends ti{constructor(e=50,t=1,n=.1,r=2e3){super(),this.isPerspectiveCamera=!0,this.type=`PerspectiveCamera`,this.fov=e,this.zoom=1,this.near=n,this.far=r,this.focus=10,this.aspect=t,this.view=null,this.filmGauge=35,this.filmOffset=0,this.updateProjectionMatrix()}copy(e,t){return super.copy(e,t),this.fov=e.fov,this.zoom=e.zoom,this.near=e.near,this.far=e.far,this.focus=e.focus,this.aspect=e.aspect,this.view=e.view===null?null:Object.assign({},e.view),this.filmGauge=e.filmGauge,this.filmOffset=e.filmOffset,this}setFocalLength(e){let t=.5*this.getFilmHeight()/e;this.fov=Ye*2*Math.atan(t),this.updateProjectionMatrix()}getFocalLength(){let e=Math.tan(Je*.5*this.fov);return .5*this.getFilmHeight()/e}getEffectiveFOV(){return Ye*2*Math.atan(Math.tan(Je*.5*this.fov)/this.zoom)}getFilmWidth(){return this.filmGauge*Math.min(this.aspect,1)}getFilmHeight(){return this.filmGauge/Math.max(this.aspect,1)}getViewBounds(e,t,n){ni.set(-1,-1,.5).applyMatrix4(this.projectionMatrixInverse),t.set(ni.x,ni.y).multiplyScalar(-e/ni.z),ni.set(1,1,.5).applyMatrix4(this.projectionMatrixInverse),n.set(ni.x,ni.y).multiplyScalar(-e/ni.z)}getViewSize(e,t){return this.getViewBounds(e,ri,ii),t.subVectors(ii,ri)}setViewOffset(e,t,n,r,i,a){this.aspect=e/t,this.view===null&&(this.view={enabled:!0,fullWidth:1,fullHeight:1,offsetX:0,offsetY:0,width:1,height:1}),this.view.enabled=!0,this.view.fullWidth=e,this.view.fullHeight=t,this.view.offsetX=n,this.view.offsetY=r,this.view.width=i,this.view.height=a,this.updateProjectionMatrix()}clearViewOffset(){this.view!==null&&(this.view.enabled=!1),this.updateProjectionMatrix()}updateProjectionMatrix(){let e=this.near,t=e*Math.tan(Je*.5*this.fov)/this.zoom,n=2*t,r=this.aspect*n,i=-.5*r,a=this.view;if(this.view!==null&&this.view.enabled){let e=a.fullWidth,o=a.fullHeight;i+=a.offsetX*r/e,t-=a.offsetY*n/o,r*=a.width/e,n*=a.height/o}let o=this.filmOffset;o!==0&&(i+=e*o/this.getFilmWidth()),this.projectionMatrix.makePerspective(i,i+r,t,t-n,e,this.far,this.coordinateSystem),this.projectionMatrixInverse.copy(this.projectionMatrix).invert()}toJSON(e){let t=super.toJSON(e);return t.object.fov=this.fov,t.object.zoom=this.zoom,t.object.near=this.near,t.object.far=this.far,t.object.focus=this.focus,t.object.aspect=this.aspect,this.view!==null&&(t.object.view=Object.assign({},this.view)),t.object.filmGauge=this.filmGauge,t.object.filmOffset=this.filmOffset,t}},oi=-90,si=1,ci=class extends Yn{constructor(e,t,n){super(),this.type=`CubeCamera`,this.renderTarget=n,this.coordinateSystem=null,this.activeMipmapLevel=0;let r=new ai(oi,si,e,t);r.layers=this.layers,this.add(r);let i=new ai(oi,si,e,t);i.layers=this.layers,this.add(i);let a=new ai(oi,si,e,t);a.layers=this.layers,this.add(a);let o=new ai(oi,si,e,t);o.layers=this.layers,this.add(o);let s=new ai(oi,si,e,t);s.layers=this.layers,this.add(s);let c=new ai(oi,si,e,t);c.layers=this.layers,this.add(c)}updateCoordinateSystem(){let e=this.coordinateSystem,t=this.children.concat(),[n,r,i,a,o,s]=t;for(let e of t)this.remove(e);if(e===2e3)n.up.set(0,1,0),n.lookAt(1,0,0),r.up.set(0,1,0),r.lookAt(-1,0,0),i.up.set(0,0,-1),i.lookAt(0,1,0),a.up.set(0,0,1),a.lookAt(0,-1,0),o.up.set(0,1,0),o.lookAt(0,0,1),s.up.set(0,1,0),s.lookAt(0,0,-1);else if(e===2001)n.up.set(0,-1,0),n.lookAt(-1,0,0),r.up.set(0,-1,0),r.lookAt(1,0,0),i.up.set(0,0,1),i.lookAt(0,1,0),a.up.set(0,0,-1),a.lookAt(0,-1,0),o.up.set(0,-1,0),o.lookAt(0,0,1),s.up.set(0,-1,0),s.lookAt(0,0,-1);else throw Error(`THREE.CubeCamera.updateCoordinateSystem(): Invalid coordinate system: `+e);for(let e of t)this.add(e),e.updateMatrixWorld()}update(e,t){this.parent===null&&this.updateMatrixWorld();let{renderTarget:n,activeMipmapLevel:r}=this;this.coordinateSystem!==e.coordinateSystem&&(this.coordinateSystem=e.coordinateSystem,this.updateCoordinateSystem());let[i,a,o,s,c,l]=this.children,u=e.getRenderTarget(),d=e.getActiveCubeFace(),f=e.getActiveMipmapLevel(),p=e.xr.enabled;e.xr.enabled=!1;let m=n.texture.generateMipmaps;n.texture.generateMipmaps=!1,e.setRenderTarget(n,0,r),e.render(t,i),e.setRenderTarget(n,1,r),e.render(t,a),e.setRenderTarget(n,2,r),e.render(t,o),e.setRenderTarget(n,3,r),e.render(t,s),e.setRenderTarget(n,4,r),e.render(t,c),n.texture.generateMipmaps=m,e.setRenderTarget(n,5,r),e.render(t,l),e.setRenderTarget(u,d,f),e.xr.enabled=p,n.texture.needsPMREMUpdate=!0}},li=class extends Ht{constructor(e,t,n,r,i,a,o,s,c,l){e=e===void 0?[]:e,t=t===void 0?301:t,super(e,t,n,r,i,a,o,s,c,l),this.isCubeTexture=!0,this.flipY=!1}get images(){return this.image}set images(e){this.image=e}},ui=class extends Wt{constructor(e=1,t={}){super(e,e,t),this.isWebGLCubeRenderTarget=!0;let n={width:e,height:e,depth:1},r=[n,n,n,n,n,n];this.texture=new li(r,t.mapping,t.wrapS,t.wrapT,t.magFilter,t.minFilter,t.format,t.type,t.anisotropy,t.colorSpace),this.texture.isRenderTargetTexture=!0,this.texture.generateMipmaps=t.generateMipmaps!==void 0&&t.generateMipmaps,this.texture.minFilter=t.minFilter===void 0?l:t.minFilter}fromEquirectangularTexture(e,t){this.texture.type=t.type,this.texture.colorSpace=t.colorSpace,this.texture.generateMipmaps=t.generateMipmaps,this.texture.minFilter=t.minFilter,this.texture.magFilter=t.magFilter;let n={uniforms:{tEquirect:{value:null}},vertexShader:`

				varying vec3 vWorldDirection;

				vec3 transformDirection( in vec3 dir, in mat4 matrix ) {

					return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );

				}

				void main() {

					vWorldDirection = transformDirection( position, modelMatrix );

					#include <begin_vertex>
					#include <project_vertex>

				}
			`,fragmentShader:`

				uniform sampler2D tEquirect;

				varying vec3 vWorldDirection;

				#include <common>

				void main() {

					vec3 direction = normalize( vWorldDirection );

					vec2 sampleUV = equirectUv( direction );

					gl_FragColor = texture2D( tEquirect, sampleUV );

				}
			`},r=new Kr(5,5,5),i=new ei({name:`CubemapFromEquirect`,uniforms:qr(n.uniforms),vertexShader:n.vertexShader,fragmentShader:n.fragmentShader,side:1,blending:0});i.uniforms.tEquirect.value=t;let a=new Ur(r,i),o=t.minFilter;return t.minFilter===1008&&(t.minFilter=l),new ci(1,10,this).update(e,a),t.minFilter=o,a.geometry.dispose(),a.material.dispose(),this}clear(e,t,n,r){let i=e.getRenderTarget();for(let i=0;i<6;i++)e.setRenderTarget(this,i),e.clear(t,n,r);e.setRenderTarget(i)}},di=new H,fi=new H,pi=new z,mi=class{constructor(e=new H(1,0,0),t=0){this.isPlane=!0,this.normal=e,this.constant=t}set(e,t){return this.normal.copy(e),this.constant=t,this}setComponents(e,t,n,r){return this.normal.set(e,t,n),this.constant=r,this}setFromNormalAndCoplanarPoint(e,t){return this.normal.copy(e),this.constant=-t.dot(this.normal),this}setFromCoplanarPoints(e,t,n){let r=di.subVectors(n,t).cross(fi.subVectors(e,t)).normalize();return this.setFromNormalAndCoplanarPoint(r,e),this}copy(e){return this.normal.copy(e.normal),this.constant=e.constant,this}normalize(){let e=1/this.normal.length();return this.normal.multiplyScalar(e),this.constant*=e,this}negate(){return this.constant*=-1,this.normal.negate(),this}distanceToPoint(e){return this.normal.dot(e)+this.constant}distanceToSphere(e){return this.distanceToPoint(e.center)-e.radius}projectPoint(e,t){return t.copy(e).addScaledVector(this.normal,-this.distanceToPoint(e))}intersectLine(e,t){let n=e.delta(di),r=this.normal.dot(n);if(r===0)return this.distanceToPoint(e.start)===0?t.copy(e.start):null;let i=-(e.start.dot(this.normal)+this.constant)/r;return i<0||i>1?null:t.copy(e.start).addScaledVector(n,i)}intersectsLine(e){let t=this.distanceToPoint(e.start),n=this.distanceToPoint(e.end);return t<0&&n>0||n<0&&t>0}intersectsBox(e){return e.intersectsPlane(this)}intersectsSphere(e){return e.intersectsPlane(this)}coplanarPoint(e){return e.copy(this.normal).multiplyScalar(-this.constant)}applyMatrix4(e,t){let n=t||pi.getNormalMatrix(e),r=this.coplanarPoint(di).applyMatrix4(e),i=this.normal.applyMatrix3(n).normalize();return this.constant=-r.dot(i),this}translate(e){return this.constant-=e.dot(this.normal),this}equals(e){return e.normal.equals(this.normal)&&e.constant===this.constant}clone(){return new this.constructor().copy(this)}},hi=new mn,gi=new H,_i=class{constructor(e=new mi,t=new mi,n=new mi,r=new mi,i=new mi,a=new mi){this.planes=[e,t,n,r,i,a]}set(e,t,n,r,i,a){let o=this.planes;return o[0].copy(e),o[1].copy(t),o[2].copy(n),o[3].copy(r),o[4].copy(i),o[5].copy(a),this}copy(e){let t=this.planes;for(let n=0;n<6;n++)t[n].copy(e.planes[n]);return this}setFromProjectionMatrix(e,t=We){let n=this.planes,r=e.elements,i=r[0],a=r[1],o=r[2],s=r[3],c=r[4],l=r[5],u=r[6],d=r[7],f=r[8],p=r[9],m=r[10],h=r[11],g=r[12],_=r[13],v=r[14],y=r[15];if(n[0].setComponents(s-i,d-c,h-f,y-g).normalize(),n[1].setComponents(s+i,d+c,h+f,y+g).normalize(),n[2].setComponents(s+a,d+l,h+p,y+_).normalize(),n[3].setComponents(s-a,d-l,h-p,y-_).normalize(),n[4].setComponents(s-o,d-u,h-m,y-v).normalize(),t===2e3)n[5].setComponents(s+o,d+u,h+m,y+v).normalize();else if(t===2001)n[5].setComponents(o,u,m,v).normalize();else throw Error(`THREE.Frustum.setFromProjectionMatrix(): Invalid coordinate system: `+t);return this}intersectsObject(e){if(e.boundingSphere!==void 0)e.boundingSphere===null&&e.computeBoundingSphere(),hi.copy(e.boundingSphere).applyMatrix4(e.matrixWorld);else{let t=e.geometry;t.boundingSphere===null&&t.computeBoundingSphere(),hi.copy(t.boundingSphere).applyMatrix4(e.matrixWorld)}return this.intersectsSphere(hi)}intersectsSprite(e){return hi.center.set(0,0,0),hi.radius=.7071067811865476,hi.applyMatrix4(e.matrixWorld),this.intersectsSphere(hi)}intersectsSphere(e){let t=this.planes,n=e.center,r=-e.radius;for(let e=0;e<6;e++)if(t[e].distanceToPoint(n)<r)return!1;return!0}intersectsBox(e){let t=this.planes;for(let n=0;n<6;n++){let r=t[n];if(gi.x=r.normal.x>0?e.max.x:e.min.x,gi.y=r.normal.y>0?e.max.y:e.min.y,gi.z=r.normal.z>0?e.max.z:e.min.z,r.distanceToPoint(gi)<0)return!1}return!0}containsPoint(e){let t=this.planes;for(let n=0;n<6;n++)if(t[n].distanceToPoint(e)<0)return!1;return!0}clone(){return new this.constructor().copy(this)}};function vi(){let e=null,t=!1,n=null,r=null;function i(t,a){n(t,a),r=e.requestAnimationFrame(i)}return{start:function(){t!==!0&&n!==null&&(r=e.requestAnimationFrame(i),t=!0)},stop:function(){e.cancelAnimationFrame(r),t=!1},setAnimationLoop:function(e){n=e},setContext:function(t){e=t}}}function yi(e){let t=new WeakMap;function n(t,n){let r=t.array,i=t.usage,a=r.byteLength,o=e.createBuffer();e.bindBuffer(n,o),e.bufferData(n,r,i),t.onUploadCallback();let s;if(r instanceof Float32Array)s=e.FLOAT;else if(r instanceof Uint16Array)s=t.isFloat16BufferAttribute?e.HALF_FLOAT:e.UNSIGNED_SHORT;else if(r instanceof Int16Array)s=e.SHORT;else if(r instanceof Uint32Array)s=e.UNSIGNED_INT;else if(r instanceof Int32Array)s=e.INT;else if(r instanceof Int8Array)s=e.BYTE;else if(r instanceof Uint8Array)s=e.UNSIGNED_BYTE;else if(r instanceof Uint8ClampedArray)s=e.UNSIGNED_BYTE;else throw Error(`THREE.WebGLAttributes: Unsupported buffer data format: `+r);return{buffer:o,type:s,bytesPerElement:r.BYTES_PER_ELEMENT,version:t.version,size:a}}function r(t,n,r){let i=n.array,a=n.updateRanges;if(e.bindBuffer(r,t),a.length===0)e.bufferSubData(r,0,i);else{a.sort((e,t)=>e.start-t.start);let t=0;for(let e=1;e<a.length;e++){let n=a[t],r=a[e];r.start<=n.start+n.count+1?n.count=Math.max(n.count,r.start+r.count-n.start):(++t,a[t]=r)}a.length=t+1;for(let t=0,n=a.length;t<n;t++){let n=a[t];e.bufferSubData(r,n.start*i.BYTES_PER_ELEMENT,i,n.start,n.count)}n.clearUpdateRanges()}n.onUploadCallback()}function i(e){return e.isInterleavedBufferAttribute&&(e=e.data),t.get(e)}function a(n){n.isInterleavedBufferAttribute&&(n=n.data);let r=t.get(n);r&&(e.deleteBuffer(r.buffer),t.delete(n))}function o(e,i){if(e.isInterleavedBufferAttribute&&(e=e.data),e.isGLBufferAttribute){let n=t.get(e);(!n||n.version<e.version)&&t.set(e,{buffer:e.buffer,type:e.type,bytesPerElement:e.elementSize,version:e.version});return}let a=t.get(e);if(a===void 0)t.set(e,n(e,i));else if(a.version<e.version){if(a.size!==e.array.byteLength)throw Error(`THREE.WebGLAttributes: The size of the buffer attribute's array buffer does not match the original size. Resizing buffer attributes is not supported.`);r(a.buffer,e,i),a.version=e.version}}return{get:i,remove:a,update:o}}var bi=class e extends jr{constructor(e=1,t=1,n=1,r=1){super(),this.type=`PlaneGeometry`,this.parameters={width:e,height:t,widthSegments:n,heightSegments:r};let i=e/2,a=t/2,o=Math.floor(n),s=Math.floor(r),c=o+1,l=s+1,u=e/o,d=t/s,f=[],p=[],m=[],h=[];for(let e=0;e<l;e++){let t=e*d-a;for(let n=0;n<c;n++){let r=n*u-i;p.push(r,-t,0),m.push(0,0,1),h.push(n/o),h.push(1-e/s)}}for(let e=0;e<s;e++)for(let t=0;t<o;t++){let n=t+c*e,r=t+c*(e+1),i=t+1+c*(e+1),a=t+1+c*e;f.push(n,r,a),f.push(r,i,a)}this.setIndex(f),this.setAttribute(`position`,new Cr(p,3)),this.setAttribute(`normal`,new Cr(m,3)),this.setAttribute(`uv`,new Cr(h,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(t){return new e(t.width,t.height,t.widthSegments,t.heightSegments)}},G={alphahash_fragment:`#ifdef USE_ALPHAHASH
	if ( diffuseColor.a < getAlphaHashThreshold( vPosition ) ) discard;
#endif`,alphahash_pars_fragment:`#ifdef USE_ALPHAHASH
	const float ALPHA_HASH_SCALE = 0.05;
	float hash2D( vec2 value ) {
		return fract( 1.0e4 * sin( 17.0 * value.x + 0.1 * value.y ) * ( 0.1 + abs( sin( 13.0 * value.y + value.x ) ) ) );
	}
	float hash3D( vec3 value ) {
		return hash2D( vec2( hash2D( value.xy ), value.z ) );
	}
	float getAlphaHashThreshold( vec3 position ) {
		float maxDeriv = max(
			length( dFdx( position.xyz ) ),
			length( dFdy( position.xyz ) )
		);
		float pixScale = 1.0 / ( ALPHA_HASH_SCALE * maxDeriv );
		vec2 pixScales = vec2(
			exp2( floor( log2( pixScale ) ) ),
			exp2( ceil( log2( pixScale ) ) )
		);
		vec2 alpha = vec2(
			hash3D( floor( pixScales.x * position.xyz ) ),
			hash3D( floor( pixScales.y * position.xyz ) )
		);
		float lerpFactor = fract( log2( pixScale ) );
		float x = ( 1.0 - lerpFactor ) * alpha.x + lerpFactor * alpha.y;
		float a = min( lerpFactor, 1.0 - lerpFactor );
		vec3 cases = vec3(
			x * x / ( 2.0 * a * ( 1.0 - a ) ),
			( x - 0.5 * a ) / ( 1.0 - a ),
			1.0 - ( ( 1.0 - x ) * ( 1.0 - x ) / ( 2.0 * a * ( 1.0 - a ) ) )
		);
		float threshold = ( x < ( 1.0 - a ) )
			? ( ( x < a ) ? cases.x : cases.y )
			: cases.z;
		return clamp( threshold , 1.0e-6, 1.0 );
	}
#endif`,alphamap_fragment:`#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;
#endif`,alphamap_pars_fragment:`#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`,alphatest_fragment:`#ifdef USE_ALPHATEST
	#ifdef ALPHA_TO_COVERAGE
	diffuseColor.a = smoothstep( alphaTest, alphaTest + fwidth( diffuseColor.a ), diffuseColor.a );
	if ( diffuseColor.a == 0.0 ) discard;
	#else
	if ( diffuseColor.a < alphaTest ) discard;
	#endif
#endif`,alphatest_pars_fragment:`#ifdef USE_ALPHATEST
	uniform float alphaTest;
#endif`,aomap_fragment:`#ifdef USE_AOMAP
	float ambientOcclusion = ( texture2D( aoMap, vAoMapUv ).r - 1.0 ) * aoMapIntensity + 1.0;
	reflectedLight.indirectDiffuse *= ambientOcclusion;
	#if defined( USE_CLEARCOAT ) 
		clearcoatSpecularIndirect *= ambientOcclusion;
	#endif
	#if defined( USE_SHEEN ) 
		sheenSpecularIndirect *= ambientOcclusion;
	#endif
	#if defined( USE_ENVMAP ) && defined( STANDARD )
		float dotNV = saturate( dot( geometryNormal, geometryViewDir ) );
		reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.roughness );
	#endif
#endif`,aomap_pars_fragment:`#ifdef USE_AOMAP
	uniform sampler2D aoMap;
	uniform float aoMapIntensity;
#endif`,batching_pars_vertex:`#ifdef USE_BATCHING
	#if ! defined( GL_ANGLE_multi_draw )
	#define gl_DrawID _gl_DrawID
	uniform int _gl_DrawID;
	#endif
	uniform highp sampler2D batchingTexture;
	uniform highp usampler2D batchingIdTexture;
	mat4 getBatchingMatrix( const in float i ) {
		int size = textureSize( batchingTexture, 0 ).x;
		int j = int( i ) * 4;
		int x = j % size;
		int y = j / size;
		vec4 v1 = texelFetch( batchingTexture, ivec2( x, y ), 0 );
		vec4 v2 = texelFetch( batchingTexture, ivec2( x + 1, y ), 0 );
		vec4 v3 = texelFetch( batchingTexture, ivec2( x + 2, y ), 0 );
		vec4 v4 = texelFetch( batchingTexture, ivec2( x + 3, y ), 0 );
		return mat4( v1, v2, v3, v4 );
	}
	float getIndirectIndex( const in int i ) {
		int size = textureSize( batchingIdTexture, 0 ).x;
		int x = i % size;
		int y = i / size;
		return float( texelFetch( batchingIdTexture, ivec2( x, y ), 0 ).r );
	}
#endif
#ifdef USE_BATCHING_COLOR
	uniform sampler2D batchingColorTexture;
	vec3 getBatchingColor( const in float i ) {
		int size = textureSize( batchingColorTexture, 0 ).x;
		int j = int( i );
		int x = j % size;
		int y = j / size;
		return texelFetch( batchingColorTexture, ivec2( x, y ), 0 ).rgb;
	}
#endif`,batching_vertex:`#ifdef USE_BATCHING
	mat4 batchingMatrix = getBatchingMatrix( getIndirectIndex( gl_DrawID ) );
#endif`,begin_vertex:`vec3 transformed = vec3( position );
#ifdef USE_ALPHAHASH
	vPosition = vec3( position );
#endif`,beginnormal_vertex:`vec3 objectNormal = vec3( normal );
#ifdef USE_TANGENT
	vec3 objectTangent = vec3( tangent.xyz );
#endif`,bsdfs:`float G_BlinnPhong_Implicit( ) {
	return 0.25;
}
float D_BlinnPhong( const in float shininess, const in float dotNH ) {
	return RECIPROCAL_PI * ( shininess * 0.5 + 1.0 ) * pow( dotNH, shininess );
}
vec3 BRDF_BlinnPhong( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in vec3 specularColor, const in float shininess ) {
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( specularColor, 1.0, dotVH );
	float G = G_BlinnPhong_Implicit( );
	float D = D_BlinnPhong( shininess, dotNH );
	return F * ( G * D );
} // validated`,iridescence_fragment:`#ifdef USE_IRIDESCENCE
	const mat3 XYZ_TO_REC709 = mat3(
		 3.2404542, -0.9692660,  0.0556434,
		-1.5371385,  1.8760108, -0.2040259,
		-0.4985314,  0.0415560,  1.0572252
	);
	vec3 Fresnel0ToIor( vec3 fresnel0 ) {
		vec3 sqrtF0 = sqrt( fresnel0 );
		return ( vec3( 1.0 ) + sqrtF0 ) / ( vec3( 1.0 ) - sqrtF0 );
	}
	vec3 IorToFresnel0( vec3 transmittedIor, float incidentIor ) {
		return pow2( ( transmittedIor - vec3( incidentIor ) ) / ( transmittedIor + vec3( incidentIor ) ) );
	}
	float IorToFresnel0( float transmittedIor, float incidentIor ) {
		return pow2( ( transmittedIor - incidentIor ) / ( transmittedIor + incidentIor ));
	}
	vec3 evalSensitivity( float OPD, vec3 shift ) {
		float phase = 2.0 * PI * OPD * 1.0e-9;
		vec3 val = vec3( 5.4856e-13, 4.4201e-13, 5.2481e-13 );
		vec3 pos = vec3( 1.6810e+06, 1.7953e+06, 2.2084e+06 );
		vec3 var = vec3( 4.3278e+09, 9.3046e+09, 6.6121e+09 );
		vec3 xyz = val * sqrt( 2.0 * PI * var ) * cos( pos * phase + shift ) * exp( - pow2( phase ) * var );
		xyz.x += 9.7470e-14 * sqrt( 2.0 * PI * 4.5282e+09 ) * cos( 2.2399e+06 * phase + shift[ 0 ] ) * exp( - 4.5282e+09 * pow2( phase ) );
		xyz /= 1.0685e-7;
		vec3 rgb = XYZ_TO_REC709 * xyz;
		return rgb;
	}
	vec3 evalIridescence( float outsideIOR, float eta2, float cosTheta1, float thinFilmThickness, vec3 baseF0 ) {
		vec3 I;
		float iridescenceIOR = mix( outsideIOR, eta2, smoothstep( 0.0, 0.03, thinFilmThickness ) );
		float sinTheta2Sq = pow2( outsideIOR / iridescenceIOR ) * ( 1.0 - pow2( cosTheta1 ) );
		float cosTheta2Sq = 1.0 - sinTheta2Sq;
		if ( cosTheta2Sq < 0.0 ) {
			return vec3( 1.0 );
		}
		float cosTheta2 = sqrt( cosTheta2Sq );
		float R0 = IorToFresnel0( iridescenceIOR, outsideIOR );
		float R12 = F_Schlick( R0, 1.0, cosTheta1 );
		float T121 = 1.0 - R12;
		float phi12 = 0.0;
		if ( iridescenceIOR < outsideIOR ) phi12 = PI;
		float phi21 = PI - phi12;
		vec3 baseIOR = Fresnel0ToIor( clamp( baseF0, 0.0, 0.9999 ) );		vec3 R1 = IorToFresnel0( baseIOR, iridescenceIOR );
		vec3 R23 = F_Schlick( R1, 1.0, cosTheta2 );
		vec3 phi23 = vec3( 0.0 );
		if ( baseIOR[ 0 ] < iridescenceIOR ) phi23[ 0 ] = PI;
		if ( baseIOR[ 1 ] < iridescenceIOR ) phi23[ 1 ] = PI;
		if ( baseIOR[ 2 ] < iridescenceIOR ) phi23[ 2 ] = PI;
		float OPD = 2.0 * iridescenceIOR * thinFilmThickness * cosTheta2;
		vec3 phi = vec3( phi21 ) + phi23;
		vec3 R123 = clamp( R12 * R23, 1e-5, 0.9999 );
		vec3 r123 = sqrt( R123 );
		vec3 Rs = pow2( T121 ) * R23 / ( vec3( 1.0 ) - R123 );
		vec3 C0 = R12 + Rs;
		I = C0;
		vec3 Cm = Rs - T121;
		for ( int m = 1; m <= 2; ++ m ) {
			Cm *= r123;
			vec3 Sm = 2.0 * evalSensitivity( float( m ) * OPD, float( m ) * phi );
			I += Cm * Sm;
		}
		return max( I, vec3( 0.0 ) );
	}
#endif`,bumpmap_pars_fragment:`#ifdef USE_BUMPMAP
	uniform sampler2D bumpMap;
	uniform float bumpScale;
	vec2 dHdxy_fwd() {
		vec2 dSTdx = dFdx( vBumpMapUv );
		vec2 dSTdy = dFdy( vBumpMapUv );
		float Hll = bumpScale * texture2D( bumpMap, vBumpMapUv ).x;
		float dBx = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdx ).x - Hll;
		float dBy = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdy ).x - Hll;
		return vec2( dBx, dBy );
	}
	vec3 perturbNormalArb( vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection ) {
		vec3 vSigmaX = normalize( dFdx( surf_pos.xyz ) );
		vec3 vSigmaY = normalize( dFdy( surf_pos.xyz ) );
		vec3 vN = surf_norm;
		vec3 R1 = cross( vSigmaY, vN );
		vec3 R2 = cross( vN, vSigmaX );
		float fDet = dot( vSigmaX, R1 ) * faceDirection;
		vec3 vGrad = sign( fDet ) * ( dHdxy.x * R1 + dHdxy.y * R2 );
		return normalize( abs( fDet ) * surf_norm - vGrad );
	}
#endif`,clipping_planes_fragment:`#if NUM_CLIPPING_PLANES > 0
	vec4 plane;
	#ifdef ALPHA_TO_COVERAGE
		float distanceToPlane, distanceGradient;
		float clipOpacity = 1.0;
		#pragma unroll_loop_start
		for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {
			plane = clippingPlanes[ i ];
			distanceToPlane = - dot( vClipPosition, plane.xyz ) + plane.w;
			distanceGradient = fwidth( distanceToPlane ) / 2.0;
			clipOpacity *= smoothstep( - distanceGradient, distanceGradient, distanceToPlane );
			if ( clipOpacity == 0.0 ) discard;
		}
		#pragma unroll_loop_end
		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES
			float unionClipOpacity = 1.0;
			#pragma unroll_loop_start
			for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {
				plane = clippingPlanes[ i ];
				distanceToPlane = - dot( vClipPosition, plane.xyz ) + plane.w;
				distanceGradient = fwidth( distanceToPlane ) / 2.0;
				unionClipOpacity *= 1.0 - smoothstep( - distanceGradient, distanceGradient, distanceToPlane );
			}
			#pragma unroll_loop_end
			clipOpacity *= 1.0 - unionClipOpacity;
		#endif
		diffuseColor.a *= clipOpacity;
		if ( diffuseColor.a == 0.0 ) discard;
	#else
		#pragma unroll_loop_start
		for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {
			plane = clippingPlanes[ i ];
			if ( dot( vClipPosition, plane.xyz ) > plane.w ) discard;
		}
		#pragma unroll_loop_end
		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES
			bool clipped = true;
			#pragma unroll_loop_start
			for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {
				plane = clippingPlanes[ i ];
				clipped = ( dot( vClipPosition, plane.xyz ) > plane.w ) && clipped;
			}
			#pragma unroll_loop_end
			if ( clipped ) discard;
		#endif
	#endif
#endif`,clipping_planes_pars_fragment:`#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
	uniform vec4 clippingPlanes[ NUM_CLIPPING_PLANES ];
#endif`,clipping_planes_pars_vertex:`#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
#endif`,clipping_planes_vertex:`#if NUM_CLIPPING_PLANES > 0
	vClipPosition = - mvPosition.xyz;
#endif`,color_fragment:`#if defined( USE_COLOR_ALPHA )
	diffuseColor *= vColor;
#elif defined( USE_COLOR )
	diffuseColor.rgb *= vColor;
#endif`,color_pars_fragment:`#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR )
	varying vec3 vColor;
#endif`,color_pars_vertex:`#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )
	varying vec3 vColor;
#endif`,color_vertex:`#if defined( USE_COLOR_ALPHA )
	vColor = vec4( 1.0 );
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )
	vColor = vec3( 1.0 );
#endif
#ifdef USE_COLOR
	vColor *= color;
#endif
#ifdef USE_INSTANCING_COLOR
	vColor.xyz *= instanceColor.xyz;
#endif
#ifdef USE_BATCHING_COLOR
	vec3 batchingColor = getBatchingColor( getIndirectIndex( gl_DrawID ) );
	vColor.xyz *= batchingColor.xyz;
#endif`,common:`#define PI 3.141592653589793
#define PI2 6.283185307179586
#define PI_HALF 1.5707963267948966
#define RECIPROCAL_PI 0.3183098861837907
#define RECIPROCAL_PI2 0.15915494309189535
#define EPSILON 1e-6
#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
#define whiteComplement( a ) ( 1.0 - saturate( a ) )
float pow2( const in float x ) { return x*x; }
vec3 pow2( const in vec3 x ) { return x*x; }
float pow3( const in float x ) { return x*x*x; }
float pow4( const in float x ) { float x2 = x*x; return x2*x2; }
float max3( const in vec3 v ) { return max( max( v.x, v.y ), v.z ); }
float average( const in vec3 v ) { return dot( v, vec3( 0.3333333 ) ); }
highp float rand( const in vec2 uv ) {
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract( sin( sn ) * c );
}
#ifdef HIGH_PRECISION
	float precisionSafeLength( vec3 v ) { return length( v ); }
#else
	float precisionSafeLength( vec3 v ) {
		float maxComponent = max3( abs( v ) );
		return length( v / maxComponent ) * maxComponent;
	}
#endif
struct IncidentLight {
	vec3 color;
	vec3 direction;
	bool visible;
};
struct ReflectedLight {
	vec3 directDiffuse;
	vec3 directSpecular;
	vec3 indirectDiffuse;
	vec3 indirectSpecular;
};
#ifdef USE_ALPHAHASH
	varying vec3 vPosition;
#endif
vec3 transformDirection( in vec3 dir, in mat4 matrix ) {
	return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );
}
vec3 inverseTransformDirection( in vec3 dir, in mat4 matrix ) {
	return normalize( ( vec4( dir, 0.0 ) * matrix ).xyz );
}
mat3 transposeMat3( const in mat3 m ) {
	mat3 tmp;
	tmp[ 0 ] = vec3( m[ 0 ].x, m[ 1 ].x, m[ 2 ].x );
	tmp[ 1 ] = vec3( m[ 0 ].y, m[ 1 ].y, m[ 2 ].y );
	tmp[ 2 ] = vec3( m[ 0 ].z, m[ 1 ].z, m[ 2 ].z );
	return tmp;
}
bool isPerspectiveMatrix( mat4 m ) {
	return m[ 2 ][ 3 ] == - 1.0;
}
vec2 equirectUv( in vec3 dir ) {
	float u = atan( dir.z, dir.x ) * RECIPROCAL_PI2 + 0.5;
	float v = asin( clamp( dir.y, - 1.0, 1.0 ) ) * RECIPROCAL_PI + 0.5;
	return vec2( u, v );
}
vec3 BRDF_Lambert( const in vec3 diffuseColor ) {
	return RECIPROCAL_PI * diffuseColor;
}
vec3 F_Schlick( const in vec3 f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
}
float F_Schlick( const in float f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
} // validated`,cube_uv_reflection_fragment:`#ifdef ENVMAP_TYPE_CUBE_UV
	#define cubeUV_minMipLevel 4.0
	#define cubeUV_minTileSize 16.0
	float getFace( vec3 direction ) {
		vec3 absDirection = abs( direction );
		float face = - 1.0;
		if ( absDirection.x > absDirection.z ) {
			if ( absDirection.x > absDirection.y )
				face = direction.x > 0.0 ? 0.0 : 3.0;
			else
				face = direction.y > 0.0 ? 1.0 : 4.0;
		} else {
			if ( absDirection.z > absDirection.y )
				face = direction.z > 0.0 ? 2.0 : 5.0;
			else
				face = direction.y > 0.0 ? 1.0 : 4.0;
		}
		return face;
	}
	vec2 getUV( vec3 direction, float face ) {
		vec2 uv;
		if ( face == 0.0 ) {
			uv = vec2( direction.z, direction.y ) / abs( direction.x );
		} else if ( face == 1.0 ) {
			uv = vec2( - direction.x, - direction.z ) / abs( direction.y );
		} else if ( face == 2.0 ) {
			uv = vec2( - direction.x, direction.y ) / abs( direction.z );
		} else if ( face == 3.0 ) {
			uv = vec2( - direction.z, direction.y ) / abs( direction.x );
		} else if ( face == 4.0 ) {
			uv = vec2( - direction.x, direction.z ) / abs( direction.y );
		} else {
			uv = vec2( direction.x, direction.y ) / abs( direction.z );
		}
		return 0.5 * ( uv + 1.0 );
	}
	vec3 bilinearCubeUV( sampler2D envMap, vec3 direction, float mipInt ) {
		float face = getFace( direction );
		float filterInt = max( cubeUV_minMipLevel - mipInt, 0.0 );
		mipInt = max( mipInt, cubeUV_minMipLevel );
		float faceSize = exp2( mipInt );
		highp vec2 uv = getUV( direction, face ) * ( faceSize - 2.0 ) + 1.0;
		if ( face > 2.0 ) {
			uv.y += faceSize;
			face -= 3.0;
		}
		uv.x += face * faceSize;
		uv.x += filterInt * 3.0 * cubeUV_minTileSize;
		uv.y += 4.0 * ( exp2( CUBEUV_MAX_MIP ) - faceSize );
		uv.x *= CUBEUV_TEXEL_WIDTH;
		uv.y *= CUBEUV_TEXEL_HEIGHT;
		#ifdef texture2DGradEXT
			return texture2DGradEXT( envMap, uv, vec2( 0.0 ), vec2( 0.0 ) ).rgb;
		#else
			return texture2D( envMap, uv ).rgb;
		#endif
	}
	#define cubeUV_r0 1.0
	#define cubeUV_m0 - 2.0
	#define cubeUV_r1 0.8
	#define cubeUV_m1 - 1.0
	#define cubeUV_r4 0.4
	#define cubeUV_m4 2.0
	#define cubeUV_r5 0.305
	#define cubeUV_m5 3.0
	#define cubeUV_r6 0.21
	#define cubeUV_m6 4.0
	float roughnessToMip( float roughness ) {
		float mip = 0.0;
		if ( roughness >= cubeUV_r1 ) {
			mip = ( cubeUV_r0 - roughness ) * ( cubeUV_m1 - cubeUV_m0 ) / ( cubeUV_r0 - cubeUV_r1 ) + cubeUV_m0;
		} else if ( roughness >= cubeUV_r4 ) {
			mip = ( cubeUV_r1 - roughness ) * ( cubeUV_m4 - cubeUV_m1 ) / ( cubeUV_r1 - cubeUV_r4 ) + cubeUV_m1;
		} else if ( roughness >= cubeUV_r5 ) {
			mip = ( cubeUV_r4 - roughness ) * ( cubeUV_m5 - cubeUV_m4 ) / ( cubeUV_r4 - cubeUV_r5 ) + cubeUV_m4;
		} else if ( roughness >= cubeUV_r6 ) {
			mip = ( cubeUV_r5 - roughness ) * ( cubeUV_m6 - cubeUV_m5 ) / ( cubeUV_r5 - cubeUV_r6 ) + cubeUV_m5;
		} else {
			mip = - 2.0 * log2( 1.16 * roughness );		}
		return mip;
	}
	vec4 textureCubeUV( sampler2D envMap, vec3 sampleDir, float roughness ) {
		float mip = clamp( roughnessToMip( roughness ), cubeUV_m0, CUBEUV_MAX_MIP );
		float mipF = fract( mip );
		float mipInt = floor( mip );
		vec3 color0 = bilinearCubeUV( envMap, sampleDir, mipInt );
		if ( mipF == 0.0 ) {
			return vec4( color0, 1.0 );
		} else {
			vec3 color1 = bilinearCubeUV( envMap, sampleDir, mipInt + 1.0 );
			return vec4( mix( color0, color1, mipF ), 1.0 );
		}
	}
#endif`,defaultnormal_vertex:`vec3 transformedNormal = objectNormal;
#ifdef USE_TANGENT
	vec3 transformedTangent = objectTangent;
#endif
#ifdef USE_BATCHING
	mat3 bm = mat3( batchingMatrix );
	transformedNormal /= vec3( dot( bm[ 0 ], bm[ 0 ] ), dot( bm[ 1 ], bm[ 1 ] ), dot( bm[ 2 ], bm[ 2 ] ) );
	transformedNormal = bm * transformedNormal;
	#ifdef USE_TANGENT
		transformedTangent = bm * transformedTangent;
	#endif
#endif
#ifdef USE_INSTANCING
	mat3 im = mat3( instanceMatrix );
	transformedNormal /= vec3( dot( im[ 0 ], im[ 0 ] ), dot( im[ 1 ], im[ 1 ] ), dot( im[ 2 ], im[ 2 ] ) );
	transformedNormal = im * transformedNormal;
	#ifdef USE_TANGENT
		transformedTangent = im * transformedTangent;
	#endif
#endif
transformedNormal = normalMatrix * transformedNormal;
#ifdef FLIP_SIDED
	transformedNormal = - transformedNormal;
#endif
#ifdef USE_TANGENT
	transformedTangent = ( modelViewMatrix * vec4( transformedTangent, 0.0 ) ).xyz;
	#ifdef FLIP_SIDED
		transformedTangent = - transformedTangent;
	#endif
#endif`,displacementmap_pars_vertex:`#ifdef USE_DISPLACEMENTMAP
	uniform sampler2D displacementMap;
	uniform float displacementScale;
	uniform float displacementBias;
#endif`,displacementmap_vertex:`#ifdef USE_DISPLACEMENTMAP
	transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vDisplacementMapUv ).x * displacementScale + displacementBias );
#endif`,emissivemap_fragment:`#ifdef USE_EMISSIVEMAP
	vec4 emissiveColor = texture2D( emissiveMap, vEmissiveMapUv );
	#ifdef DECODE_VIDEO_TEXTURE_EMISSIVE
		emissiveColor = sRGBTransferEOTF( emissiveColor );
	#endif
	totalEmissiveRadiance *= emissiveColor.rgb;
#endif`,emissivemap_pars_fragment:`#ifdef USE_EMISSIVEMAP
	uniform sampler2D emissiveMap;
#endif`,colorspace_fragment:`gl_FragColor = linearToOutputTexel( gl_FragColor );`,colorspace_pars_fragment:`vec4 LinearTransferOETF( in vec4 value ) {
	return value;
}
vec4 sRGBTransferEOTF( in vec4 value ) {
	return vec4( mix( pow( value.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), value.rgb * 0.0773993808, vec3( lessThanEqual( value.rgb, vec3( 0.04045 ) ) ) ), value.a );
}
vec4 sRGBTransferOETF( in vec4 value ) {
	return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
}`,envmap_fragment:`#ifdef USE_ENVMAP
	#ifdef ENV_WORLDPOS
		vec3 cameraToFrag;
		if ( isOrthographic ) {
			cameraToFrag = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
		} else {
			cameraToFrag = normalize( vWorldPosition - cameraPosition );
		}
		vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
		#ifdef ENVMAP_MODE_REFLECTION
			vec3 reflectVec = reflect( cameraToFrag, worldNormal );
		#else
			vec3 reflectVec = refract( cameraToFrag, worldNormal, refractionRatio );
		#endif
	#else
		vec3 reflectVec = vReflect;
	#endif
	#ifdef ENVMAP_TYPE_CUBE
		vec4 envColor = textureCube( envMap, envMapRotation * vec3( flipEnvMap * reflectVec.x, reflectVec.yz ) );
	#else
		vec4 envColor = vec4( 0.0 );
	#endif
	#ifdef ENVMAP_BLENDING_MULTIPLY
		outgoingLight = mix( outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity );
	#elif defined( ENVMAP_BLENDING_MIX )
		outgoingLight = mix( outgoingLight, envColor.xyz, specularStrength * reflectivity );
	#elif defined( ENVMAP_BLENDING_ADD )
		outgoingLight += envColor.xyz * specularStrength * reflectivity;
	#endif
#endif`,envmap_common_pars_fragment:`#ifdef USE_ENVMAP
	uniform float envMapIntensity;
	uniform float flipEnvMap;
	uniform mat3 envMapRotation;
	#ifdef ENVMAP_TYPE_CUBE
		uniform samplerCube envMap;
	#else
		uniform sampler2D envMap;
	#endif
	
#endif`,envmap_pars_fragment:`#ifdef USE_ENVMAP
	uniform float reflectivity;
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		varying vec3 vWorldPosition;
		uniform float refractionRatio;
	#else
		varying vec3 vReflect;
	#endif
#endif`,envmap_pars_vertex:`#ifdef USE_ENVMAP
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		
		varying vec3 vWorldPosition;
	#else
		varying vec3 vReflect;
		uniform float refractionRatio;
	#endif
#endif`,envmap_physical_pars_fragment:`#ifdef USE_ENVMAP
	vec3 getIBLIrradiance( const in vec3 normal ) {
		#ifdef ENVMAP_TYPE_CUBE_UV
			vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, envMapRotation * worldNormal, 1.0 );
			return PI * envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	vec3 getIBLRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness ) {
		#ifdef ENVMAP_TYPE_CUBE_UV
			vec3 reflectVec = reflect( - viewDir, normal );
			reflectVec = normalize( mix( reflectVec, normal, roughness * roughness) );
			reflectVec = inverseTransformDirection( reflectVec, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, envMapRotation * reflectVec, roughness );
			return envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	#ifdef USE_ANISOTROPY
		vec3 getIBLAnisotropyRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness, const in vec3 bitangent, const in float anisotropy ) {
			#ifdef ENVMAP_TYPE_CUBE_UV
				vec3 bentNormal = cross( bitangent, viewDir );
				bentNormal = normalize( cross( bentNormal, bitangent ) );
				bentNormal = normalize( mix( bentNormal, normal, pow2( pow2( 1.0 - anisotropy * ( 1.0 - roughness ) ) ) ) );
				return getIBLRadiance( viewDir, bentNormal, roughness );
			#else
				return vec3( 0.0 );
			#endif
		}
	#endif
#endif`,envmap_vertex:`#ifdef USE_ENVMAP
	#ifdef ENV_WORLDPOS
		vWorldPosition = worldPosition.xyz;
	#else
		vec3 cameraToVertex;
		if ( isOrthographic ) {
			cameraToVertex = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
		} else {
			cameraToVertex = normalize( worldPosition.xyz - cameraPosition );
		}
		vec3 worldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
		#ifdef ENVMAP_MODE_REFLECTION
			vReflect = reflect( cameraToVertex, worldNormal );
		#else
			vReflect = refract( cameraToVertex, worldNormal, refractionRatio );
		#endif
	#endif
#endif`,fog_vertex:`#ifdef USE_FOG
	vFogDepth = - mvPosition.z;
#endif`,fog_pars_vertex:`#ifdef USE_FOG
	varying float vFogDepth;
#endif`,fog_fragment:`#ifdef USE_FOG
	#ifdef FOG_EXP2
		float fogFactor = 1.0 - exp( - fogDensity * fogDensity * vFogDepth * vFogDepth );
	#else
		float fogFactor = smoothstep( fogNear, fogFar, vFogDepth );
	#endif
	gl_FragColor.rgb = mix( gl_FragColor.rgb, fogColor, fogFactor );
#endif`,fog_pars_fragment:`#ifdef USE_FOG
	uniform vec3 fogColor;
	varying float vFogDepth;
	#ifdef FOG_EXP2
		uniform float fogDensity;
	#else
		uniform float fogNear;
		uniform float fogFar;
	#endif
#endif`,gradientmap_pars_fragment:`#ifdef USE_GRADIENTMAP
	uniform sampler2D gradientMap;
#endif
vec3 getGradientIrradiance( vec3 normal, vec3 lightDirection ) {
	float dotNL = dot( normal, lightDirection );
	vec2 coord = vec2( dotNL * 0.5 + 0.5, 0.0 );
	#ifdef USE_GRADIENTMAP
		return vec3( texture2D( gradientMap, coord ).r );
	#else
		vec2 fw = fwidth( coord ) * 0.5;
		return mix( vec3( 0.7 ), vec3( 1.0 ), smoothstep( 0.7 - fw.x, 0.7 + fw.x, coord.x ) );
	#endif
}`,lightmap_pars_fragment:`#ifdef USE_LIGHTMAP
	uniform sampler2D lightMap;
	uniform float lightMapIntensity;
#endif`,lights_lambert_fragment:`LambertMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularStrength = specularStrength;`,lights_lambert_pars_fragment:`varying vec3 vViewPosition;
struct LambertMaterial {
	vec3 diffuseColor;
	float specularStrength;
};
void RE_Direct_Lambert( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Lambert( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Lambert
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Lambert`,lights_pars_begin:`uniform bool receiveShadow;
uniform vec3 ambientLightColor;
#if defined( USE_LIGHT_PROBES )
	uniform vec3 lightProbe[ 9 ];
#endif
vec3 shGetIrradianceAt( in vec3 normal, in vec3 shCoefficients[ 9 ] ) {
	float x = normal.x, y = normal.y, z = normal.z;
	vec3 result = shCoefficients[ 0 ] * 0.886227;
	result += shCoefficients[ 1 ] * 2.0 * 0.511664 * y;
	result += shCoefficients[ 2 ] * 2.0 * 0.511664 * z;
	result += shCoefficients[ 3 ] * 2.0 * 0.511664 * x;
	result += shCoefficients[ 4 ] * 2.0 * 0.429043 * x * y;
	result += shCoefficients[ 5 ] * 2.0 * 0.429043 * y * z;
	result += shCoefficients[ 6 ] * ( 0.743125 * z * z - 0.247708 );
	result += shCoefficients[ 7 ] * 2.0 * 0.429043 * x * z;
	result += shCoefficients[ 8 ] * 0.429043 * ( x * x - y * y );
	return result;
}
vec3 getLightProbeIrradiance( const in vec3 lightProbe[ 9 ], const in vec3 normal ) {
	vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
	vec3 irradiance = shGetIrradianceAt( worldNormal, lightProbe );
	return irradiance;
}
vec3 getAmbientLightIrradiance( const in vec3 ambientLightColor ) {
	vec3 irradiance = ambientLightColor;
	return irradiance;
}
float getDistanceAttenuation( const in float lightDistance, const in float cutoffDistance, const in float decayExponent ) {
	float distanceFalloff = 1.0 / max( pow( lightDistance, decayExponent ), 0.01 );
	if ( cutoffDistance > 0.0 ) {
		distanceFalloff *= pow2( saturate( 1.0 - pow4( lightDistance / cutoffDistance ) ) );
	}
	return distanceFalloff;
}
float getSpotAttenuation( const in float coneCosine, const in float penumbraCosine, const in float angleCosine ) {
	return smoothstep( coneCosine, penumbraCosine, angleCosine );
}
#if NUM_DIR_LIGHTS > 0
	struct DirectionalLight {
		vec3 direction;
		vec3 color;
	};
	uniform DirectionalLight directionalLights[ NUM_DIR_LIGHTS ];
	void getDirectionalLightInfo( const in DirectionalLight directionalLight, out IncidentLight light ) {
		light.color = directionalLight.color;
		light.direction = directionalLight.direction;
		light.visible = true;
	}
#endif
#if NUM_POINT_LIGHTS > 0
	struct PointLight {
		vec3 position;
		vec3 color;
		float distance;
		float decay;
	};
	uniform PointLight pointLights[ NUM_POINT_LIGHTS ];
	void getPointLightInfo( const in PointLight pointLight, const in vec3 geometryPosition, out IncidentLight light ) {
		vec3 lVector = pointLight.position - geometryPosition;
		light.direction = normalize( lVector );
		float lightDistance = length( lVector );
		light.color = pointLight.color;
		light.color *= getDistanceAttenuation( lightDistance, pointLight.distance, pointLight.decay );
		light.visible = ( light.color != vec3( 0.0 ) );
	}
#endif
#if NUM_SPOT_LIGHTS > 0
	struct SpotLight {
		vec3 position;
		vec3 direction;
		vec3 color;
		float distance;
		float decay;
		float coneCos;
		float penumbraCos;
	};
	uniform SpotLight spotLights[ NUM_SPOT_LIGHTS ];
	void getSpotLightInfo( const in SpotLight spotLight, const in vec3 geometryPosition, out IncidentLight light ) {
		vec3 lVector = spotLight.position - geometryPosition;
		light.direction = normalize( lVector );
		float angleCos = dot( light.direction, spotLight.direction );
		float spotAttenuation = getSpotAttenuation( spotLight.coneCos, spotLight.penumbraCos, angleCos );
		if ( spotAttenuation > 0.0 ) {
			float lightDistance = length( lVector );
			light.color = spotLight.color * spotAttenuation;
			light.color *= getDistanceAttenuation( lightDistance, spotLight.distance, spotLight.decay );
			light.visible = ( light.color != vec3( 0.0 ) );
		} else {
			light.color = vec3( 0.0 );
			light.visible = false;
		}
	}
#endif
#if NUM_RECT_AREA_LIGHTS > 0
	struct RectAreaLight {
		vec3 color;
		vec3 position;
		vec3 halfWidth;
		vec3 halfHeight;
	};
	uniform sampler2D ltc_1;	uniform sampler2D ltc_2;
	uniform RectAreaLight rectAreaLights[ NUM_RECT_AREA_LIGHTS ];
#endif
#if NUM_HEMI_LIGHTS > 0
	struct HemisphereLight {
		vec3 direction;
		vec3 skyColor;
		vec3 groundColor;
	};
	uniform HemisphereLight hemisphereLights[ NUM_HEMI_LIGHTS ];
	vec3 getHemisphereLightIrradiance( const in HemisphereLight hemiLight, const in vec3 normal ) {
		float dotNL = dot( normal, hemiLight.direction );
		float hemiDiffuseWeight = 0.5 * dotNL + 0.5;
		vec3 irradiance = mix( hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight );
		return irradiance;
	}
#endif`,lights_toon_fragment:`ToonMaterial material;
material.diffuseColor = diffuseColor.rgb;`,lights_toon_pars_fragment:`varying vec3 vViewPosition;
struct ToonMaterial {
	vec3 diffuseColor;
};
void RE_Direct_Toon( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	vec3 irradiance = getGradientIrradiance( geometryNormal, directLight.direction ) * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Toon( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Toon
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Toon`,lights_phong_fragment:`BlinnPhongMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularColor = specular;
material.specularShininess = shininess;
material.specularStrength = specularStrength;`,lights_phong_pars_fragment:`varying vec3 vViewPosition;
struct BlinnPhongMaterial {
	vec3 diffuseColor;
	vec3 specularColor;
	float specularShininess;
	float specularStrength;
};
void RE_Direct_BlinnPhong( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
	reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong( directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess ) * material.specularStrength;
}
void RE_IndirectDiffuse_BlinnPhong( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_BlinnPhong
#define RE_IndirectDiffuse		RE_IndirectDiffuse_BlinnPhong`,lights_physical_fragment:`PhysicalMaterial material;
material.diffuseColor = diffuseColor.rgb * ( 1.0 - metalnessFactor );
vec3 dxy = max( abs( dFdx( nonPerturbedNormal ) ), abs( dFdy( nonPerturbedNormal ) ) );
float geometryRoughness = max( max( dxy.x, dxy.y ), dxy.z );
material.roughness = max( roughnessFactor, 0.0525 );material.roughness += geometryRoughness;
material.roughness = min( material.roughness, 1.0 );
#ifdef IOR
	material.ior = ior;
	#ifdef USE_SPECULAR
		float specularIntensityFactor = specularIntensity;
		vec3 specularColorFactor = specularColor;
		#ifdef USE_SPECULAR_COLORMAP
			specularColorFactor *= texture2D( specularColorMap, vSpecularColorMapUv ).rgb;
		#endif
		#ifdef USE_SPECULAR_INTENSITYMAP
			specularIntensityFactor *= texture2D( specularIntensityMap, vSpecularIntensityMapUv ).a;
		#endif
		material.specularF90 = mix( specularIntensityFactor, 1.0, metalnessFactor );
	#else
		float specularIntensityFactor = 1.0;
		vec3 specularColorFactor = vec3( 1.0 );
		material.specularF90 = 1.0;
	#endif
	material.specularColor = mix( min( pow2( ( material.ior - 1.0 ) / ( material.ior + 1.0 ) ) * specularColorFactor, vec3( 1.0 ) ) * specularIntensityFactor, diffuseColor.rgb, metalnessFactor );
#else
	material.specularColor = mix( vec3( 0.04 ), diffuseColor.rgb, metalnessFactor );
	material.specularF90 = 1.0;
#endif
#ifdef USE_CLEARCOAT
	material.clearcoat = clearcoat;
	material.clearcoatRoughness = clearcoatRoughness;
	material.clearcoatF0 = vec3( 0.04 );
	material.clearcoatF90 = 1.0;
	#ifdef USE_CLEARCOATMAP
		material.clearcoat *= texture2D( clearcoatMap, vClearcoatMapUv ).x;
	#endif
	#ifdef USE_CLEARCOAT_ROUGHNESSMAP
		material.clearcoatRoughness *= texture2D( clearcoatRoughnessMap, vClearcoatRoughnessMapUv ).y;
	#endif
	material.clearcoat = saturate( material.clearcoat );	material.clearcoatRoughness = max( material.clearcoatRoughness, 0.0525 );
	material.clearcoatRoughness += geometryRoughness;
	material.clearcoatRoughness = min( material.clearcoatRoughness, 1.0 );
#endif
#ifdef USE_DISPERSION
	material.dispersion = dispersion;
#endif
#ifdef USE_IRIDESCENCE
	material.iridescence = iridescence;
	material.iridescenceIOR = iridescenceIOR;
	#ifdef USE_IRIDESCENCEMAP
		material.iridescence *= texture2D( iridescenceMap, vIridescenceMapUv ).r;
	#endif
	#ifdef USE_IRIDESCENCE_THICKNESSMAP
		material.iridescenceThickness = (iridescenceThicknessMaximum - iridescenceThicknessMinimum) * texture2D( iridescenceThicknessMap, vIridescenceThicknessMapUv ).g + iridescenceThicknessMinimum;
	#else
		material.iridescenceThickness = iridescenceThicknessMaximum;
	#endif
#endif
#ifdef USE_SHEEN
	material.sheenColor = sheenColor;
	#ifdef USE_SHEEN_COLORMAP
		material.sheenColor *= texture2D( sheenColorMap, vSheenColorMapUv ).rgb;
	#endif
	material.sheenRoughness = clamp( sheenRoughness, 0.07, 1.0 );
	#ifdef USE_SHEEN_ROUGHNESSMAP
		material.sheenRoughness *= texture2D( sheenRoughnessMap, vSheenRoughnessMapUv ).a;
	#endif
#endif
#ifdef USE_ANISOTROPY
	#ifdef USE_ANISOTROPYMAP
		mat2 anisotropyMat = mat2( anisotropyVector.x, anisotropyVector.y, - anisotropyVector.y, anisotropyVector.x );
		vec3 anisotropyPolar = texture2D( anisotropyMap, vAnisotropyMapUv ).rgb;
		vec2 anisotropyV = anisotropyMat * normalize( 2.0 * anisotropyPolar.rg - vec2( 1.0 ) ) * anisotropyPolar.b;
	#else
		vec2 anisotropyV = anisotropyVector;
	#endif
	material.anisotropy = length( anisotropyV );
	if( material.anisotropy == 0.0 ) {
		anisotropyV = vec2( 1.0, 0.0 );
	} else {
		anisotropyV /= material.anisotropy;
		material.anisotropy = saturate( material.anisotropy );
	}
	material.alphaT = mix( pow2( material.roughness ), 1.0, pow2( material.anisotropy ) );
	material.anisotropyT = tbn[ 0 ] * anisotropyV.x + tbn[ 1 ] * anisotropyV.y;
	material.anisotropyB = tbn[ 1 ] * anisotropyV.x - tbn[ 0 ] * anisotropyV.y;
#endif`,lights_physical_pars_fragment:`struct PhysicalMaterial {
	vec3 diffuseColor;
	float roughness;
	vec3 specularColor;
	float specularF90;
	float dispersion;
	#ifdef USE_CLEARCOAT
		float clearcoat;
		float clearcoatRoughness;
		vec3 clearcoatF0;
		float clearcoatF90;
	#endif
	#ifdef USE_IRIDESCENCE
		float iridescence;
		float iridescenceIOR;
		float iridescenceThickness;
		vec3 iridescenceFresnel;
		vec3 iridescenceF0;
	#endif
	#ifdef USE_SHEEN
		vec3 sheenColor;
		float sheenRoughness;
	#endif
	#ifdef IOR
		float ior;
	#endif
	#ifdef USE_TRANSMISSION
		float transmission;
		float transmissionAlpha;
		float thickness;
		float attenuationDistance;
		vec3 attenuationColor;
	#endif
	#ifdef USE_ANISOTROPY
		float anisotropy;
		float alphaT;
		vec3 anisotropyT;
		vec3 anisotropyB;
	#endif
};
vec3 clearcoatSpecularDirect = vec3( 0.0 );
vec3 clearcoatSpecularIndirect = vec3( 0.0 );
vec3 sheenSpecularDirect = vec3( 0.0 );
vec3 sheenSpecularIndirect = vec3(0.0 );
vec3 Schlick_to_F0( const in vec3 f, const in float f90, const in float dotVH ) {
    float x = clamp( 1.0 - dotVH, 0.0, 1.0 );
    float x2 = x * x;
    float x5 = clamp( x * x2 * x2, 0.0, 0.9999 );
    return ( f - vec3( f90 ) * x5 ) / ( 1.0 - x5 );
}
float V_GGX_SmithCorrelated( const in float alpha, const in float dotNL, const in float dotNV ) {
	float a2 = pow2( alpha );
	float gv = dotNL * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNV ) );
	float gl = dotNV * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNL ) );
	return 0.5 / max( gv + gl, EPSILON );
}
float D_GGX( const in float alpha, const in float dotNH ) {
	float a2 = pow2( alpha );
	float denom = pow2( dotNH ) * ( a2 - 1.0 ) + 1.0;
	return RECIPROCAL_PI * a2 / pow2( denom );
}
#ifdef USE_ANISOTROPY
	float V_GGX_SmithCorrelated_Anisotropic( const in float alphaT, const in float alphaB, const in float dotTV, const in float dotBV, const in float dotTL, const in float dotBL, const in float dotNV, const in float dotNL ) {
		float gv = dotNL * length( vec3( alphaT * dotTV, alphaB * dotBV, dotNV ) );
		float gl = dotNV * length( vec3( alphaT * dotTL, alphaB * dotBL, dotNL ) );
		float v = 0.5 / ( gv + gl );
		return saturate(v);
	}
	float D_GGX_Anisotropic( const in float alphaT, const in float alphaB, const in float dotNH, const in float dotTH, const in float dotBH ) {
		float a2 = alphaT * alphaB;
		highp vec3 v = vec3( alphaB * dotTH, alphaT * dotBH, a2 * dotNH );
		highp float v2 = dot( v, v );
		float w2 = a2 / v2;
		return RECIPROCAL_PI * a2 * pow2 ( w2 );
	}
#endif
#ifdef USE_CLEARCOAT
	vec3 BRDF_GGX_Clearcoat( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material) {
		vec3 f0 = material.clearcoatF0;
		float f90 = material.clearcoatF90;
		float roughness = material.clearcoatRoughness;
		float alpha = pow2( roughness );
		vec3 halfDir = normalize( lightDir + viewDir );
		float dotNL = saturate( dot( normal, lightDir ) );
		float dotNV = saturate( dot( normal, viewDir ) );
		float dotNH = saturate( dot( normal, halfDir ) );
		float dotVH = saturate( dot( viewDir, halfDir ) );
		vec3 F = F_Schlick( f0, f90, dotVH );
		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
		float D = D_GGX( alpha, dotNH );
		return F * ( V * D );
	}
#endif
vec3 BRDF_GGX( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material ) {
	vec3 f0 = material.specularColor;
	float f90 = material.specularF90;
	float roughness = material.roughness;
	float alpha = pow2( roughness );
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( f0, f90, dotVH );
	#ifdef USE_IRIDESCENCE
		F = mix( F, material.iridescenceFresnel, material.iridescence );
	#endif
	#ifdef USE_ANISOTROPY
		float dotTL = dot( material.anisotropyT, lightDir );
		float dotTV = dot( material.anisotropyT, viewDir );
		float dotTH = dot( material.anisotropyT, halfDir );
		float dotBL = dot( material.anisotropyB, lightDir );
		float dotBV = dot( material.anisotropyB, viewDir );
		float dotBH = dot( material.anisotropyB, halfDir );
		float V = V_GGX_SmithCorrelated_Anisotropic( material.alphaT, alpha, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL );
		float D = D_GGX_Anisotropic( material.alphaT, alpha, dotNH, dotTH, dotBH );
	#else
		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
		float D = D_GGX( alpha, dotNH );
	#endif
	return F * ( V * D );
}
vec2 LTC_Uv( const in vec3 N, const in vec3 V, const in float roughness ) {
	const float LUT_SIZE = 64.0;
	const float LUT_SCALE = ( LUT_SIZE - 1.0 ) / LUT_SIZE;
	const float LUT_BIAS = 0.5 / LUT_SIZE;
	float dotNV = saturate( dot( N, V ) );
	vec2 uv = vec2( roughness, sqrt( 1.0 - dotNV ) );
	uv = uv * LUT_SCALE + LUT_BIAS;
	return uv;
}
float LTC_ClippedSphereFormFactor( const in vec3 f ) {
	float l = length( f );
	return max( ( l * l + f.z ) / ( l + 1.0 ), 0.0 );
}
vec3 LTC_EdgeVectorFormFactor( const in vec3 v1, const in vec3 v2 ) {
	float x = dot( v1, v2 );
	float y = abs( x );
	float a = 0.8543985 + ( 0.4965155 + 0.0145206 * y ) * y;
	float b = 3.4175940 + ( 4.1616724 + y ) * y;
	float v = a / b;
	float theta_sintheta = ( x > 0.0 ) ? v : 0.5 * inversesqrt( max( 1.0 - x * x, 1e-7 ) ) - v;
	return cross( v1, v2 ) * theta_sintheta;
}
vec3 LTC_Evaluate( const in vec3 N, const in vec3 V, const in vec3 P, const in mat3 mInv, const in vec3 rectCoords[ 4 ] ) {
	vec3 v1 = rectCoords[ 1 ] - rectCoords[ 0 ];
	vec3 v2 = rectCoords[ 3 ] - rectCoords[ 0 ];
	vec3 lightNormal = cross( v1, v2 );
	if( dot( lightNormal, P - rectCoords[ 0 ] ) < 0.0 ) return vec3( 0.0 );
	vec3 T1, T2;
	T1 = normalize( V - N * dot( V, N ) );
	T2 = - cross( N, T1 );
	mat3 mat = mInv * transposeMat3( mat3( T1, T2, N ) );
	vec3 coords[ 4 ];
	coords[ 0 ] = mat * ( rectCoords[ 0 ] - P );
	coords[ 1 ] = mat * ( rectCoords[ 1 ] - P );
	coords[ 2 ] = mat * ( rectCoords[ 2 ] - P );
	coords[ 3 ] = mat * ( rectCoords[ 3 ] - P );
	coords[ 0 ] = normalize( coords[ 0 ] );
	coords[ 1 ] = normalize( coords[ 1 ] );
	coords[ 2 ] = normalize( coords[ 2 ] );
	coords[ 3 ] = normalize( coords[ 3 ] );
	vec3 vectorFormFactor = vec3( 0.0 );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 0 ], coords[ 1 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 1 ], coords[ 2 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 2 ], coords[ 3 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 3 ], coords[ 0 ] );
	float result = LTC_ClippedSphereFormFactor( vectorFormFactor );
	return vec3( result );
}
#if defined( USE_SHEEN )
float D_Charlie( float roughness, float dotNH ) {
	float alpha = pow2( roughness );
	float invAlpha = 1.0 / alpha;
	float cos2h = dotNH * dotNH;
	float sin2h = max( 1.0 - cos2h, 0.0078125 );
	return ( 2.0 + invAlpha ) * pow( sin2h, invAlpha * 0.5 ) / ( 2.0 * PI );
}
float V_Neubelt( float dotNV, float dotNL ) {
	return saturate( 1.0 / ( 4.0 * ( dotNL + dotNV - dotNL * dotNV ) ) );
}
vec3 BRDF_Sheen( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, vec3 sheenColor, const in float sheenRoughness ) {
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float D = D_Charlie( sheenRoughness, dotNH );
	float V = V_Neubelt( dotNV, dotNL );
	return sheenColor * ( D * V );
}
#endif
float IBLSheenBRDF( const in vec3 normal, const in vec3 viewDir, const in float roughness ) {
	float dotNV = saturate( dot( normal, viewDir ) );
	float r2 = roughness * roughness;
	float a = roughness < 0.25 ? -339.2 * r2 + 161.4 * roughness - 25.9 : -8.48 * r2 + 14.3 * roughness - 9.95;
	float b = roughness < 0.25 ? 44.0 * r2 - 23.7 * roughness + 3.26 : 1.97 * r2 - 3.27 * roughness + 0.72;
	float DG = exp( a * dotNV + b ) + ( roughness < 0.25 ? 0.0 : 0.1 * ( roughness - 0.25 ) );
	return saturate( DG * RECIPROCAL_PI );
}
vec2 DFGApprox( const in vec3 normal, const in vec3 viewDir, const in float roughness ) {
	float dotNV = saturate( dot( normal, viewDir ) );
	const vec4 c0 = vec4( - 1, - 0.0275, - 0.572, 0.022 );
	const vec4 c1 = vec4( 1, 0.0425, 1.04, - 0.04 );
	vec4 r = roughness * c0 + c1;
	float a004 = min( r.x * r.x, exp2( - 9.28 * dotNV ) ) * r.x + r.y;
	vec2 fab = vec2( - 1.04, 1.04 ) * a004 + r.zw;
	return fab;
}
vec3 EnvironmentBRDF( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness ) {
	vec2 fab = DFGApprox( normal, viewDir, roughness );
	return specularColor * fab.x + specularF90 * fab.y;
}
#ifdef USE_IRIDESCENCE
void computeMultiscatteringIridescence( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float iridescence, const in vec3 iridescenceF0, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter ) {
#else
void computeMultiscattering( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter ) {
#endif
	vec2 fab = DFGApprox( normal, viewDir, roughness );
	#ifdef USE_IRIDESCENCE
		vec3 Fr = mix( specularColor, iridescenceF0, iridescence );
	#else
		vec3 Fr = specularColor;
	#endif
	vec3 FssEss = Fr * fab.x + specularF90 * fab.y;
	float Ess = fab.x + fab.y;
	float Ems = 1.0 - Ess;
	vec3 Favg = Fr + ( 1.0 - Fr ) * 0.047619;	vec3 Fms = FssEss * Favg / ( 1.0 - Ems * Favg );
	singleScatter += FssEss;
	multiScatter += Fms * Ems;
}
#if NUM_RECT_AREA_LIGHTS > 0
	void RE_Direct_RectArea_Physical( const in RectAreaLight rectAreaLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
		vec3 normal = geometryNormal;
		vec3 viewDir = geometryViewDir;
		vec3 position = geometryPosition;
		vec3 lightPos = rectAreaLight.position;
		vec3 halfWidth = rectAreaLight.halfWidth;
		vec3 halfHeight = rectAreaLight.halfHeight;
		vec3 lightColor = rectAreaLight.color;
		float roughness = material.roughness;
		vec3 rectCoords[ 4 ];
		rectCoords[ 0 ] = lightPos + halfWidth - halfHeight;		rectCoords[ 1 ] = lightPos - halfWidth - halfHeight;
		rectCoords[ 2 ] = lightPos - halfWidth + halfHeight;
		rectCoords[ 3 ] = lightPos + halfWidth + halfHeight;
		vec2 uv = LTC_Uv( normal, viewDir, roughness );
		vec4 t1 = texture2D( ltc_1, uv );
		vec4 t2 = texture2D( ltc_2, uv );
		mat3 mInv = mat3(
			vec3( t1.x, 0, t1.y ),
			vec3(    0, 1,    0 ),
			vec3( t1.z, 0, t1.w )
		);
		vec3 fresnel = ( material.specularColor * t2.x + ( vec3( 1.0 ) - material.specularColor ) * t2.y );
		reflectedLight.directSpecular += lightColor * fresnel * LTC_Evaluate( normal, viewDir, position, mInv, rectCoords );
		reflectedLight.directDiffuse += lightColor * material.diffuseColor * LTC_Evaluate( normal, viewDir, position, mat3( 1.0 ), rectCoords );
	}
#endif
void RE_Direct_Physical( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	#ifdef USE_CLEARCOAT
		float dotNLcc = saturate( dot( geometryClearcoatNormal, directLight.direction ) );
		vec3 ccIrradiance = dotNLcc * directLight.color;
		clearcoatSpecularDirect += ccIrradiance * BRDF_GGX_Clearcoat( directLight.direction, geometryViewDir, geometryClearcoatNormal, material );
	#endif
	#ifdef USE_SHEEN
		sheenSpecularDirect += irradiance * BRDF_Sheen( directLight.direction, geometryViewDir, geometryNormal, material.sheenColor, material.sheenRoughness );
	#endif
	reflectedLight.directSpecular += irradiance * BRDF_GGX( directLight.direction, geometryViewDir, geometryNormal, material );
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Physical( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectSpecular_Physical( const in vec3 radiance, const in vec3 irradiance, const in vec3 clearcoatRadiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight) {
	#ifdef USE_CLEARCOAT
		clearcoatSpecularIndirect += clearcoatRadiance * EnvironmentBRDF( geometryClearcoatNormal, geometryViewDir, material.clearcoatF0, material.clearcoatF90, material.clearcoatRoughness );
	#endif
	#ifdef USE_SHEEN
		sheenSpecularIndirect += irradiance * material.sheenColor * IBLSheenBRDF( geometryNormal, geometryViewDir, material.sheenRoughness );
	#endif
	vec3 singleScattering = vec3( 0.0 );
	vec3 multiScattering = vec3( 0.0 );
	vec3 cosineWeightedIrradiance = irradiance * RECIPROCAL_PI;
	#ifdef USE_IRIDESCENCE
		computeMultiscatteringIridescence( geometryNormal, geometryViewDir, material.specularColor, material.specularF90, material.iridescence, material.iridescenceFresnel, material.roughness, singleScattering, multiScattering );
	#else
		computeMultiscattering( geometryNormal, geometryViewDir, material.specularColor, material.specularF90, material.roughness, singleScattering, multiScattering );
	#endif
	vec3 totalScattering = singleScattering + multiScattering;
	vec3 diffuse = material.diffuseColor * ( 1.0 - max( max( totalScattering.r, totalScattering.g ), totalScattering.b ) );
	reflectedLight.indirectSpecular += radiance * singleScattering;
	reflectedLight.indirectSpecular += multiScattering * cosineWeightedIrradiance;
	reflectedLight.indirectDiffuse += diffuse * cosineWeightedIrradiance;
}
#define RE_Direct				RE_Direct_Physical
#define RE_Direct_RectArea		RE_Direct_RectArea_Physical
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Physical
#define RE_IndirectSpecular		RE_IndirectSpecular_Physical
float computeSpecularOcclusion( const in float dotNV, const in float ambientOcclusion, const in float roughness ) {
	return saturate( pow( dotNV + ambientOcclusion, exp2( - 16.0 * roughness - 1.0 ) ) - 1.0 + ambientOcclusion );
}`,lights_fragment_begin:`
vec3 geometryPosition = - vViewPosition;
vec3 geometryNormal = normal;
vec3 geometryViewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );
vec3 geometryClearcoatNormal = vec3( 0.0 );
#ifdef USE_CLEARCOAT
	geometryClearcoatNormal = clearcoatNormal;
#endif
#ifdef USE_IRIDESCENCE
	float dotNVi = saturate( dot( normal, geometryViewDir ) );
	if ( material.iridescenceThickness == 0.0 ) {
		material.iridescence = 0.0;
	} else {
		material.iridescence = saturate( material.iridescence );
	}
	if ( material.iridescence > 0.0 ) {
		material.iridescenceFresnel = evalIridescence( 1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor );
		material.iridescenceF0 = Schlick_to_F0( material.iridescenceFresnel, 1.0, dotNVi );
	}
#endif
IncidentLight directLight;
#if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )
	PointLight pointLight;
	#if defined( USE_SHADOWMAP ) && NUM_POINT_LIGHT_SHADOWS > 0
	PointLightShadow pointLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {
		pointLight = pointLights[ i ];
		getPointLightInfo( pointLight, geometryPosition, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS )
		pointLightShadow = pointLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowIntensity, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )
	SpotLight spotLight;
	vec4 spotColor;
	vec3 spotLightCoord;
	bool inSpotLightMap;
	#if defined( USE_SHADOWMAP ) && NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHTS; i ++ ) {
		spotLight = spotLights[ i ];
		getSpotLightInfo( spotLight, geometryPosition, directLight );
		#if ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
		#define SPOT_LIGHT_MAP_INDEX UNROLLED_LOOP_INDEX
		#elif ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		#define SPOT_LIGHT_MAP_INDEX NUM_SPOT_LIGHT_MAPS
		#else
		#define SPOT_LIGHT_MAP_INDEX ( UNROLLED_LOOP_INDEX - NUM_SPOT_LIGHT_SHADOWS + NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
		#endif
		#if ( SPOT_LIGHT_MAP_INDEX < NUM_SPOT_LIGHT_MAPS )
			spotLightCoord = vSpotLightCoord[ i ].xyz / vSpotLightCoord[ i ].w;
			inSpotLightMap = all( lessThan( abs( spotLightCoord * 2. - 1. ), vec3( 1.0 ) ) );
			spotColor = texture2D( spotLightMap[ SPOT_LIGHT_MAP_INDEX ], spotLightCoord.xy );
			directLight.color = inSpotLightMap ? directLight.color * spotColor.rgb : directLight.color;
		#endif
		#undef SPOT_LIGHT_MAP_INDEX
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		spotLightShadow = spotLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( spotShadowMap[ i ], spotLightShadow.shadowMapSize, spotLightShadow.shadowIntensity, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct )
	DirectionalLight directionalLight;
	#if defined( USE_SHADOWMAP ) && NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHTS; i ++ ) {
		directionalLight = directionalLights[ i ];
		getDirectionalLightInfo( directionalLight, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS )
		directionalLightShadow = directionalLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( directionalShadowMap[ i ], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowIntensity, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )
	RectAreaLight rectAreaLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_RECT_AREA_LIGHTS; i ++ ) {
		rectAreaLight = rectAreaLights[ i ];
		RE_Direct_RectArea( rectAreaLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if defined( RE_IndirectDiffuse )
	vec3 iblIrradiance = vec3( 0.0 );
	vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );
	#if defined( USE_LIGHT_PROBES )
		irradiance += getLightProbeIrradiance( lightProbe, geometryNormal );
	#endif
	#if ( NUM_HEMI_LIGHTS > 0 )
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_HEMI_LIGHTS; i ++ ) {
			irradiance += getHemisphereLightIrradiance( hemisphereLights[ i ], geometryNormal );
		}
		#pragma unroll_loop_end
	#endif
#endif
#if defined( RE_IndirectSpecular )
	vec3 radiance = vec3( 0.0 );
	vec3 clearcoatRadiance = vec3( 0.0 );
#endif`,lights_fragment_maps:`#if defined( RE_IndirectDiffuse )
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
		irradiance += lightMapIrradiance;
	#endif
	#if defined( USE_ENVMAP ) && defined( STANDARD ) && defined( ENVMAP_TYPE_CUBE_UV )
		iblIrradiance += getIBLIrradiance( geometryNormal );
	#endif
#endif
#if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )
	#ifdef USE_ANISOTROPY
		radiance += getIBLAnisotropyRadiance( geometryViewDir, geometryNormal, material.roughness, material.anisotropyB, material.anisotropy );
	#else
		radiance += getIBLRadiance( geometryViewDir, geometryNormal, material.roughness );
	#endif
	#ifdef USE_CLEARCOAT
		clearcoatRadiance += getIBLRadiance( geometryViewDir, geometryClearcoatNormal, material.clearcoatRoughness );
	#endif
#endif`,lights_fragment_end:`#if defined( RE_IndirectDiffuse )
	RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
#endif
#if defined( RE_IndirectSpecular )
	RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
#endif`,logdepthbuf_fragment:`#if defined( USE_LOGDEPTHBUF )
	gl_FragDepth = vIsPerspective == 0.0 ? gl_FragCoord.z : log2( vFragDepth ) * logDepthBufFC * 0.5;
#endif`,logdepthbuf_pars_fragment:`#if defined( USE_LOGDEPTHBUF )
	uniform float logDepthBufFC;
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`,logdepthbuf_pars_vertex:`#ifdef USE_LOGDEPTHBUF
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`,logdepthbuf_vertex:`#ifdef USE_LOGDEPTHBUF
	vFragDepth = 1.0 + gl_Position.w;
	vIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );
#endif`,map_fragment:`#ifdef USE_MAP
	vec4 sampledDiffuseColor = texture2D( map, vMapUv );
	#ifdef DECODE_VIDEO_TEXTURE
		sampledDiffuseColor = sRGBTransferEOTF( sampledDiffuseColor );
	#endif
	diffuseColor *= sampledDiffuseColor;
#endif`,map_pars_fragment:`#ifdef USE_MAP
	uniform sampler2D map;
#endif`,map_particle_fragment:`#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
	#if defined( USE_POINTS_UV )
		vec2 uv = vUv;
	#else
		vec2 uv = ( uvTransform * vec3( gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1 ) ).xy;
	#endif
#endif
#ifdef USE_MAP
	diffuseColor *= texture2D( map, uv );
#endif
#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, uv ).g;
#endif`,map_particle_pars_fragment:`#if defined( USE_POINTS_UV )
	varying vec2 vUv;
#else
	#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
		uniform mat3 uvTransform;
	#endif
#endif
#ifdef USE_MAP
	uniform sampler2D map;
#endif
#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`,metalnessmap_fragment:`float metalnessFactor = metalness;
#ifdef USE_METALNESSMAP
	vec4 texelMetalness = texture2D( metalnessMap, vMetalnessMapUv );
	metalnessFactor *= texelMetalness.b;
#endif`,metalnessmap_pars_fragment:`#ifdef USE_METALNESSMAP
	uniform sampler2D metalnessMap;
#endif`,morphinstance_vertex:`#ifdef USE_INSTANCING_MORPH
	float morphTargetInfluences[ MORPHTARGETS_COUNT ];
	float morphTargetBaseInfluence = texelFetch( morphTexture, ivec2( 0, gl_InstanceID ), 0 ).r;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		morphTargetInfluences[i] =  texelFetch( morphTexture, ivec2( i + 1, gl_InstanceID ), 0 ).r;
	}
#endif`,morphcolor_vertex:`#if defined( USE_MORPHCOLORS )
	vColor *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		#if defined( USE_COLOR_ALPHA )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ) * morphTargetInfluences[ i ];
		#elif defined( USE_COLOR )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ).rgb * morphTargetInfluences[ i ];
		#endif
	}
#endif`,morphnormal_vertex:`#ifdef USE_MORPHNORMALS
	objectNormal *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		if ( morphTargetInfluences[ i ] != 0.0 ) objectNormal += getMorph( gl_VertexID, i, 1 ).xyz * morphTargetInfluences[ i ];
	}
#endif`,morphtarget_pars_vertex:`#ifdef USE_MORPHTARGETS
	#ifndef USE_INSTANCING_MORPH
		uniform float morphTargetBaseInfluence;
		uniform float morphTargetInfluences[ MORPHTARGETS_COUNT ];
	#endif
	uniform sampler2DArray morphTargetsTexture;
	uniform ivec2 morphTargetsTextureSize;
	vec4 getMorph( const in int vertexIndex, const in int morphTargetIndex, const in int offset ) {
		int texelIndex = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
		int y = texelIndex / morphTargetsTextureSize.x;
		int x = texelIndex - y * morphTargetsTextureSize.x;
		ivec3 morphUV = ivec3( x, y, morphTargetIndex );
		return texelFetch( morphTargetsTexture, morphUV, 0 );
	}
#endif`,morphtarget_vertex:`#ifdef USE_MORPHTARGETS
	transformed *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		if ( morphTargetInfluences[ i ] != 0.0 ) transformed += getMorph( gl_VertexID, i, 0 ).xyz * morphTargetInfluences[ i ];
	}
#endif`,normal_fragment_begin:`float faceDirection = gl_FrontFacing ? 1.0 : - 1.0;
#ifdef FLAT_SHADED
	vec3 fdx = dFdx( vViewPosition );
	vec3 fdy = dFdy( vViewPosition );
	vec3 normal = normalize( cross( fdx, fdy ) );
#else
	vec3 normal = normalize( vNormal );
	#ifdef DOUBLE_SIDED
		normal *= faceDirection;
	#endif
#endif
#if defined( USE_NORMALMAP_TANGENTSPACE ) || defined( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY )
	#ifdef USE_TANGENT
		mat3 tbn = mat3( normalize( vTangent ), normalize( vBitangent ), normal );
	#else
		mat3 tbn = getTangentFrame( - vViewPosition, normal,
		#if defined( USE_NORMALMAP )
			vNormalMapUv
		#elif defined( USE_CLEARCOAT_NORMALMAP )
			vClearcoatNormalMapUv
		#else
			vUv
		#endif
		);
	#endif
	#if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )
		tbn[0] *= faceDirection;
		tbn[1] *= faceDirection;
	#endif
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	#ifdef USE_TANGENT
		mat3 tbn2 = mat3( normalize( vTangent ), normalize( vBitangent ), normal );
	#else
		mat3 tbn2 = getTangentFrame( - vViewPosition, normal, vClearcoatNormalMapUv );
	#endif
	#if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )
		tbn2[0] *= faceDirection;
		tbn2[1] *= faceDirection;
	#endif
#endif
vec3 nonPerturbedNormal = normal;`,normal_fragment_maps:`#ifdef USE_NORMALMAP_OBJECTSPACE
	normal = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	#ifdef FLIP_SIDED
		normal = - normal;
	#endif
	#ifdef DOUBLE_SIDED
		normal = normal * faceDirection;
	#endif
	normal = normalize( normalMatrix * normal );
#elif defined( USE_NORMALMAP_TANGENTSPACE )
	vec3 mapN = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	mapN.xy *= normalScale;
	normal = normalize( tbn * mapN );
#elif defined( USE_BUMPMAP )
	normal = perturbNormalArb( - vViewPosition, normal, dHdxy_fwd(), faceDirection );
#endif`,normal_pars_fragment:`#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`,normal_pars_vertex:`#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`,normal_vertex:`#ifndef FLAT_SHADED
	vNormal = normalize( transformedNormal );
	#ifdef USE_TANGENT
		vTangent = normalize( transformedTangent );
		vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );
	#endif
#endif`,normalmap_pars_fragment:`#ifdef USE_NORMALMAP
	uniform sampler2D normalMap;
	uniform vec2 normalScale;
#endif
#ifdef USE_NORMALMAP_OBJECTSPACE
	uniform mat3 normalMatrix;
#endif
#if ! defined ( USE_TANGENT ) && ( defined ( USE_NORMALMAP_TANGENTSPACE ) || defined ( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY ) )
	mat3 getTangentFrame( vec3 eye_pos, vec3 surf_norm, vec2 uv ) {
		vec3 q0 = dFdx( eye_pos.xyz );
		vec3 q1 = dFdy( eye_pos.xyz );
		vec2 st0 = dFdx( uv.st );
		vec2 st1 = dFdy( uv.st );
		vec3 N = surf_norm;
		vec3 q1perp = cross( q1, N );
		vec3 q0perp = cross( N, q0 );
		vec3 T = q1perp * st0.x + q0perp * st1.x;
		vec3 B = q1perp * st0.y + q0perp * st1.y;
		float det = max( dot( T, T ), dot( B, B ) );
		float scale = ( det == 0.0 ) ? 0.0 : inversesqrt( det );
		return mat3( T * scale, B * scale, N );
	}
#endif`,clearcoat_normal_fragment_begin:`#ifdef USE_CLEARCOAT
	vec3 clearcoatNormal = nonPerturbedNormal;
#endif`,clearcoat_normal_fragment_maps:`#ifdef USE_CLEARCOAT_NORMALMAP
	vec3 clearcoatMapN = texture2D( clearcoatNormalMap, vClearcoatNormalMapUv ).xyz * 2.0 - 1.0;
	clearcoatMapN.xy *= clearcoatNormalScale;
	clearcoatNormal = normalize( tbn2 * clearcoatMapN );
#endif`,clearcoat_pars_fragment:`#ifdef USE_CLEARCOATMAP
	uniform sampler2D clearcoatMap;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform sampler2D clearcoatNormalMap;
	uniform vec2 clearcoatNormalScale;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform sampler2D clearcoatRoughnessMap;
#endif`,iridescence_pars_fragment:`#ifdef USE_IRIDESCENCEMAP
	uniform sampler2D iridescenceMap;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform sampler2D iridescenceThicknessMap;
#endif`,opaque_fragment:`#ifdef OPAQUE
diffuseColor.a = 1.0;
#endif
#ifdef USE_TRANSMISSION
diffuseColor.a *= material.transmissionAlpha;
#endif
gl_FragColor = vec4( outgoingLight, diffuseColor.a );`,packing:`vec3 packNormalToRGB( const in vec3 normal ) {
	return normalize( normal ) * 0.5 + 0.5;
}
vec3 unpackRGBToNormal( const in vec3 rgb ) {
	return 2.0 * rgb.xyz - 1.0;
}
const float PackUpscale = 256. / 255.;const float UnpackDownscale = 255. / 256.;const float ShiftRight8 = 1. / 256.;
const float Inv255 = 1. / 255.;
const vec4 PackFactors = vec4( 1.0, 256.0, 256.0 * 256.0, 256.0 * 256.0 * 256.0 );
const vec2 UnpackFactors2 = vec2( UnpackDownscale, 1.0 / PackFactors.g );
const vec3 UnpackFactors3 = vec3( UnpackDownscale / PackFactors.rg, 1.0 / PackFactors.b );
const vec4 UnpackFactors4 = vec4( UnpackDownscale / PackFactors.rgb, 1.0 / PackFactors.a );
vec4 packDepthToRGBA( const in float v ) {
	if( v <= 0.0 )
		return vec4( 0., 0., 0., 0. );
	if( v >= 1.0 )
		return vec4( 1., 1., 1., 1. );
	float vuf;
	float af = modf( v * PackFactors.a, vuf );
	float bf = modf( vuf * ShiftRight8, vuf );
	float gf = modf( vuf * ShiftRight8, vuf );
	return vec4( vuf * Inv255, gf * PackUpscale, bf * PackUpscale, af );
}
vec3 packDepthToRGB( const in float v ) {
	if( v <= 0.0 )
		return vec3( 0., 0., 0. );
	if( v >= 1.0 )
		return vec3( 1., 1., 1. );
	float vuf;
	float bf = modf( v * PackFactors.b, vuf );
	float gf = modf( vuf * ShiftRight8, vuf );
	return vec3( vuf * Inv255, gf * PackUpscale, bf );
}
vec2 packDepthToRG( const in float v ) {
	if( v <= 0.0 )
		return vec2( 0., 0. );
	if( v >= 1.0 )
		return vec2( 1., 1. );
	float vuf;
	float gf = modf( v * 256., vuf );
	return vec2( vuf * Inv255, gf );
}
float unpackRGBAToDepth( const in vec4 v ) {
	return dot( v, UnpackFactors4 );
}
float unpackRGBToDepth( const in vec3 v ) {
	return dot( v, UnpackFactors3 );
}
float unpackRGToDepth( const in vec2 v ) {
	return v.r * UnpackFactors2.r + v.g * UnpackFactors2.g;
}
vec4 pack2HalfToRGBA( const in vec2 v ) {
	vec4 r = vec4( v.x, fract( v.x * 255.0 ), v.y, fract( v.y * 255.0 ) );
	return vec4( r.x - r.y / 255.0, r.y, r.z - r.w / 255.0, r.w );
}
vec2 unpackRGBATo2Half( const in vec4 v ) {
	return vec2( v.x + ( v.y / 255.0 ), v.z + ( v.w / 255.0 ) );
}
float viewZToOrthographicDepth( const in float viewZ, const in float near, const in float far ) {
	return ( viewZ + near ) / ( near - far );
}
float orthographicDepthToViewZ( const in float depth, const in float near, const in float far ) {
	return depth * ( near - far ) - near;
}
float viewZToPerspectiveDepth( const in float viewZ, const in float near, const in float far ) {
	return ( ( near + viewZ ) * far ) / ( ( far - near ) * viewZ );
}
float perspectiveDepthToViewZ( const in float depth, const in float near, const in float far ) {
	return ( near * far ) / ( ( far - near ) * depth - far );
}`,premultiplied_alpha_fragment:`#ifdef PREMULTIPLIED_ALPHA
	gl_FragColor.rgb *= gl_FragColor.a;
#endif`,project_vertex:`vec4 mvPosition = vec4( transformed, 1.0 );
#ifdef USE_BATCHING
	mvPosition = batchingMatrix * mvPosition;
#endif
#ifdef USE_INSTANCING
	mvPosition = instanceMatrix * mvPosition;
#endif
mvPosition = modelViewMatrix * mvPosition;
gl_Position = projectionMatrix * mvPosition;`,dithering_fragment:`#ifdef DITHERING
	gl_FragColor.rgb = dithering( gl_FragColor.rgb );
#endif`,dithering_pars_fragment:`#ifdef DITHERING
	vec3 dithering( vec3 color ) {
		float grid_position = rand( gl_FragCoord.xy );
		vec3 dither_shift_RGB = vec3( 0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0 );
		dither_shift_RGB = mix( 2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position );
		return color + dither_shift_RGB;
	}
#endif`,roughnessmap_fragment:`float roughnessFactor = roughness;
#ifdef USE_ROUGHNESSMAP
	vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );
	roughnessFactor *= texelRoughness.g;
#endif`,roughnessmap_pars_fragment:`#ifdef USE_ROUGHNESSMAP
	uniform sampler2D roughnessMap;
#endif`,shadowmap_pars_fragment:`#if NUM_SPOT_LIGHT_COORDS > 0
	varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];
#endif
#if NUM_SPOT_LIGHT_MAPS > 0
	uniform sampler2D spotLightMap[ NUM_SPOT_LIGHT_MAPS ];
#endif
#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
		uniform sampler2D directionalShadowMap[ NUM_DIR_LIGHT_SHADOWS ];
		varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];
		struct DirectionalLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
		uniform sampler2D spotShadowMap[ NUM_SPOT_LIGHT_SHADOWS ];
		struct SpotLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		uniform sampler2D pointShadowMap[ NUM_POINT_LIGHT_SHADOWS ];
		varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];
		struct PointLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
			float shadowCameraNear;
			float shadowCameraFar;
		};
		uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];
	#endif
	float texture2DCompare( sampler2D depths, vec2 uv, float compare ) {
		return step( compare, unpackRGBAToDepth( texture2D( depths, uv ) ) );
	}
	vec2 texture2DDistribution( sampler2D shadow, vec2 uv ) {
		return unpackRGBATo2Half( texture2D( shadow, uv ) );
	}
	float VSMShadow (sampler2D shadow, vec2 uv, float compare ){
		float occlusion = 1.0;
		vec2 distribution = texture2DDistribution( shadow, uv );
		float hard_shadow = step( compare , distribution.x );
		if (hard_shadow != 1.0 ) {
			float distance = compare - distribution.x ;
			float variance = max( 0.00000, distribution.y * distribution.y );
			float softness_probability = variance / (variance + distance * distance );			softness_probability = clamp( ( softness_probability - 0.3 ) / ( 0.95 - 0.3 ), 0.0, 1.0 );			occlusion = clamp( max( hard_shadow, softness_probability ), 0.0, 1.0 );
		}
		return occlusion;
	}
	float getShadow( sampler2D shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord ) {
		float shadow = 1.0;
		shadowCoord.xyz /= shadowCoord.w;
		shadowCoord.z += shadowBias;
		bool inFrustum = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
		bool frustumTest = inFrustum && shadowCoord.z <= 1.0;
		if ( frustumTest ) {
		#if defined( SHADOWMAP_TYPE_PCF )
			vec2 texelSize = vec2( 1.0 ) / shadowMapSize;
			float dx0 = - texelSize.x * shadowRadius;
			float dy0 = - texelSize.y * shadowRadius;
			float dx1 = + texelSize.x * shadowRadius;
			float dy1 = + texelSize.y * shadowRadius;
			float dx2 = dx0 / 2.0;
			float dy2 = dy0 / 2.0;
			float dx3 = dx1 / 2.0;
			float dy3 = dy1 / 2.0;
			shadow = (
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy, shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, dy1 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy1 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, dy1 ), shadowCoord.z )
			) * ( 1.0 / 17.0 );
		#elif defined( SHADOWMAP_TYPE_PCF_SOFT )
			vec2 texelSize = vec2( 1.0 ) / shadowMapSize;
			float dx = texelSize.x;
			float dy = texelSize.y;
			vec2 uv = shadowCoord.xy;
			vec2 f = fract( uv * shadowMapSize + 0.5 );
			uv -= f * texelSize;
			shadow = (
				texture2DCompare( shadowMap, uv, shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + vec2( dx, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + vec2( 0.0, dy ), shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + texelSize, shadowCoord.z ) +
				mix( texture2DCompare( shadowMap, uv + vec2( -dx, 0.0 ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, 0.0 ), shadowCoord.z ),
					 f.x ) +
				mix( texture2DCompare( shadowMap, uv + vec2( -dx, dy ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, dy ), shadowCoord.z ),
					 f.x ) +
				mix( texture2DCompare( shadowMap, uv + vec2( 0.0, -dy ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( 0.0, 2.0 * dy ), shadowCoord.z ),
					 f.y ) +
				mix( texture2DCompare( shadowMap, uv + vec2( dx, -dy ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( dx, 2.0 * dy ), shadowCoord.z ),
					 f.y ) +
				mix( mix( texture2DCompare( shadowMap, uv + vec2( -dx, -dy ), shadowCoord.z ),
						  texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, -dy ), shadowCoord.z ),
						  f.x ),
					 mix( texture2DCompare( shadowMap, uv + vec2( -dx, 2.0 * dy ), shadowCoord.z ),
						  texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, 2.0 * dy ), shadowCoord.z ),
						  f.x ),
					 f.y )
			) * ( 1.0 / 9.0 );
		#elif defined( SHADOWMAP_TYPE_VSM )
			shadow = VSMShadow( shadowMap, shadowCoord.xy, shadowCoord.z );
		#else
			shadow = texture2DCompare( shadowMap, shadowCoord.xy, shadowCoord.z );
		#endif
		}
		return mix( 1.0, shadow, shadowIntensity );
	}
	vec2 cubeToUV( vec3 v, float texelSizeY ) {
		vec3 absV = abs( v );
		float scaleToCube = 1.0 / max( absV.x, max( absV.y, absV.z ) );
		absV *= scaleToCube;
		v *= scaleToCube * ( 1.0 - 2.0 * texelSizeY );
		vec2 planar = v.xy;
		float almostATexel = 1.5 * texelSizeY;
		float almostOne = 1.0 - almostATexel;
		if ( absV.z >= almostOne ) {
			if ( v.z > 0.0 )
				planar.x = 4.0 - v.x;
		} else if ( absV.x >= almostOne ) {
			float signX = sign( v.x );
			planar.x = v.z * signX + 2.0 * signX;
		} else if ( absV.y >= almostOne ) {
			float signY = sign( v.y );
			planar.x = v.x + 2.0 * signY + 2.0;
			planar.y = v.z * signY - 2.0;
		}
		return vec2( 0.125, 0.25 ) * planar + vec2( 0.375, 0.75 );
	}
	float getPointShadow( sampler2D shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord, float shadowCameraNear, float shadowCameraFar ) {
		float shadow = 1.0;
		vec3 lightToPosition = shadowCoord.xyz;
		
		float lightToPositionLength = length( lightToPosition );
		if ( lightToPositionLength - shadowCameraFar <= 0.0 && lightToPositionLength - shadowCameraNear >= 0.0 ) {
			float dp = ( lightToPositionLength - shadowCameraNear ) / ( shadowCameraFar - shadowCameraNear );			dp += shadowBias;
			vec3 bd3D = normalize( lightToPosition );
			vec2 texelSize = vec2( 1.0 ) / ( shadowMapSize * vec2( 4.0, 2.0 ) );
			#if defined( SHADOWMAP_TYPE_PCF ) || defined( SHADOWMAP_TYPE_PCF_SOFT ) || defined( SHADOWMAP_TYPE_VSM )
				vec2 offset = vec2( - 1, 1 ) * shadowRadius * texelSize.y;
				shadow = (
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xyy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yyy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xyx, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yyx, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xxy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yxy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xxx, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yxx, texelSize.y ), dp )
				) * ( 1.0 / 9.0 );
			#else
				shadow = texture2DCompare( shadowMap, cubeToUV( bd3D, texelSize.y ), dp );
			#endif
		}
		return mix( 1.0, shadow, shadowIntensity );
	}
#endif`,shadowmap_pars_vertex:`#if NUM_SPOT_LIGHT_COORDS > 0
	uniform mat4 spotLightMatrix[ NUM_SPOT_LIGHT_COORDS ];
	varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];
#endif
#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
		uniform mat4 directionalShadowMatrix[ NUM_DIR_LIGHT_SHADOWS ];
		varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];
		struct DirectionalLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
		struct SpotLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		uniform mat4 pointShadowMatrix[ NUM_POINT_LIGHT_SHADOWS ];
		varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];
		struct PointLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
			float shadowCameraNear;
			float shadowCameraFar;
		};
		uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];
	#endif
#endif`,shadowmap_vertex:`#if ( defined( USE_SHADOWMAP ) && ( NUM_DIR_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0 ) ) || ( NUM_SPOT_LIGHT_COORDS > 0 )
	vec3 shadowWorldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
	vec4 shadowWorldPosition;
#endif
#if defined( USE_SHADOWMAP )
	#if NUM_DIR_LIGHT_SHADOWS > 0
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * directionalLightShadows[ i ].shadowNormalBias, 0 );
			vDirectionalShadowCoord[ i ] = directionalShadowMatrix[ i ] * shadowWorldPosition;
		}
		#pragma unroll_loop_end
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {
			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * pointLightShadows[ i ].shadowNormalBias, 0 );
			vPointShadowCoord[ i ] = pointShadowMatrix[ i ] * shadowWorldPosition;
		}
		#pragma unroll_loop_end
	#endif
#endif
#if NUM_SPOT_LIGHT_COORDS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_COORDS; i ++ ) {
		shadowWorldPosition = worldPosition;
		#if ( defined( USE_SHADOWMAP ) && UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
			shadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[ i ].shadowNormalBias;
		#endif
		vSpotLightCoord[ i ] = spotLightMatrix[ i ] * shadowWorldPosition;
	}
	#pragma unroll_loop_end
#endif`,shadowmask_pars_fragment:`float getShadowMask() {
	float shadow = 1.0;
	#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
		directionalLight = directionalLightShadows[ i ];
		shadow *= receiveShadow ? getShadow( directionalShadowMap[ i ], directionalLight.shadowMapSize, directionalLight.shadowIntensity, directionalLight.shadowBias, directionalLight.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_SHADOWS; i ++ ) {
		spotLight = spotLightShadows[ i ];
		shadow *= receiveShadow ? getShadow( spotShadowMap[ i ], spotLight.shadowMapSize, spotLight.shadowIntensity, spotLight.shadowBias, spotLight.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
	PointLightShadow pointLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {
		pointLight = pointLightShadows[ i ];
		shadow *= receiveShadow ? getPointShadow( pointShadowMap[ i ], pointLight.shadowMapSize, pointLight.shadowIntensity, pointLight.shadowBias, pointLight.shadowRadius, vPointShadowCoord[ i ], pointLight.shadowCameraNear, pointLight.shadowCameraFar ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#endif
	return shadow;
}`,skinbase_vertex:`#ifdef USE_SKINNING
	mat4 boneMatX = getBoneMatrix( skinIndex.x );
	mat4 boneMatY = getBoneMatrix( skinIndex.y );
	mat4 boneMatZ = getBoneMatrix( skinIndex.z );
	mat4 boneMatW = getBoneMatrix( skinIndex.w );
#endif`,skinning_pars_vertex:`#ifdef USE_SKINNING
	uniform mat4 bindMatrix;
	uniform mat4 bindMatrixInverse;
	uniform highp sampler2D boneTexture;
	mat4 getBoneMatrix( const in float i ) {
		int size = textureSize( boneTexture, 0 ).x;
		int j = int( i ) * 4;
		int x = j % size;
		int y = j / size;
		vec4 v1 = texelFetch( boneTexture, ivec2( x, y ), 0 );
		vec4 v2 = texelFetch( boneTexture, ivec2( x + 1, y ), 0 );
		vec4 v3 = texelFetch( boneTexture, ivec2( x + 2, y ), 0 );
		vec4 v4 = texelFetch( boneTexture, ivec2( x + 3, y ), 0 );
		return mat4( v1, v2, v3, v4 );
	}
#endif`,skinning_vertex:`#ifdef USE_SKINNING
	vec4 skinVertex = bindMatrix * vec4( transformed, 1.0 );
	vec4 skinned = vec4( 0.0 );
	skinned += boneMatX * skinVertex * skinWeight.x;
	skinned += boneMatY * skinVertex * skinWeight.y;
	skinned += boneMatZ * skinVertex * skinWeight.z;
	skinned += boneMatW * skinVertex * skinWeight.w;
	transformed = ( bindMatrixInverse * skinned ).xyz;
#endif`,skinnormal_vertex:`#ifdef USE_SKINNING
	mat4 skinMatrix = mat4( 0.0 );
	skinMatrix += skinWeight.x * boneMatX;
	skinMatrix += skinWeight.y * boneMatY;
	skinMatrix += skinWeight.z * boneMatZ;
	skinMatrix += skinWeight.w * boneMatW;
	skinMatrix = bindMatrixInverse * skinMatrix * bindMatrix;
	objectNormal = vec4( skinMatrix * vec4( objectNormal, 0.0 ) ).xyz;
	#ifdef USE_TANGENT
		objectTangent = vec4( skinMatrix * vec4( objectTangent, 0.0 ) ).xyz;
	#endif
#endif`,specularmap_fragment:`float specularStrength;
#ifdef USE_SPECULARMAP
	vec4 texelSpecular = texture2D( specularMap, vSpecularMapUv );
	specularStrength = texelSpecular.r;
#else
	specularStrength = 1.0;
#endif`,specularmap_pars_fragment:`#ifdef USE_SPECULARMAP
	uniform sampler2D specularMap;
#endif`,tonemapping_fragment:`#if defined( TONE_MAPPING )
	gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
#endif`,tonemapping_pars_fragment:`#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
uniform float toneMappingExposure;
vec3 LinearToneMapping( vec3 color ) {
	return saturate( toneMappingExposure * color );
}
vec3 ReinhardToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	return saturate( color / ( vec3( 1.0 ) + color ) );
}
vec3 CineonToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	color = max( vec3( 0.0 ), color - 0.004 );
	return pow( ( color * ( 6.2 * color + 0.5 ) ) / ( color * ( 6.2 * color + 1.7 ) + 0.06 ), vec3( 2.2 ) );
}
vec3 RRTAndODTFit( vec3 v ) {
	vec3 a = v * ( v + 0.0245786 ) - 0.000090537;
	vec3 b = v * ( 0.983729 * v + 0.4329510 ) + 0.238081;
	return a / b;
}
vec3 ACESFilmicToneMapping( vec3 color ) {
	const mat3 ACESInputMat = mat3(
		vec3( 0.59719, 0.07600, 0.02840 ),		vec3( 0.35458, 0.90834, 0.13383 ),
		vec3( 0.04823, 0.01566, 0.83777 )
	);
	const mat3 ACESOutputMat = mat3(
		vec3(  1.60475, -0.10208, -0.00327 ),		vec3( -0.53108,  1.10813, -0.07276 ),
		vec3( -0.07367, -0.00605,  1.07602 )
	);
	color *= toneMappingExposure / 0.6;
	color = ACESInputMat * color;
	color = RRTAndODTFit( color );
	color = ACESOutputMat * color;
	return saturate( color );
}
const mat3 LINEAR_REC2020_TO_LINEAR_SRGB = mat3(
	vec3( 1.6605, - 0.1246, - 0.0182 ),
	vec3( - 0.5876, 1.1329, - 0.1006 ),
	vec3( - 0.0728, - 0.0083, 1.1187 )
);
const mat3 LINEAR_SRGB_TO_LINEAR_REC2020 = mat3(
	vec3( 0.6274, 0.0691, 0.0164 ),
	vec3( 0.3293, 0.9195, 0.0880 ),
	vec3( 0.0433, 0.0113, 0.8956 )
);
vec3 agxDefaultContrastApprox( vec3 x ) {
	vec3 x2 = x * x;
	vec3 x4 = x2 * x2;
	return + 15.5 * x4 * x2
		- 40.14 * x4 * x
		+ 31.96 * x4
		- 6.868 * x2 * x
		+ 0.4298 * x2
		+ 0.1191 * x
		- 0.00232;
}
vec3 AgXToneMapping( vec3 color ) {
	const mat3 AgXInsetMatrix = mat3(
		vec3( 0.856627153315983, 0.137318972929847, 0.11189821299995 ),
		vec3( 0.0951212405381588, 0.761241990602591, 0.0767994186031903 ),
		vec3( 0.0482516061458583, 0.101439036467562, 0.811302368396859 )
	);
	const mat3 AgXOutsetMatrix = mat3(
		vec3( 1.1271005818144368, - 0.1413297634984383, - 0.14132976349843826 ),
		vec3( - 0.11060664309660323, 1.157823702216272, - 0.11060664309660294 ),
		vec3( - 0.016493938717834573, - 0.016493938717834257, 1.2519364065950405 )
	);
	const float AgxMinEv = - 12.47393;	const float AgxMaxEv = 4.026069;
	color *= toneMappingExposure;
	color = LINEAR_SRGB_TO_LINEAR_REC2020 * color;
	color = AgXInsetMatrix * color;
	color = max( color, 1e-10 );	color = log2( color );
	color = ( color - AgxMinEv ) / ( AgxMaxEv - AgxMinEv );
	color = clamp( color, 0.0, 1.0 );
	color = agxDefaultContrastApprox( color );
	color = AgXOutsetMatrix * color;
	color = pow( max( vec3( 0.0 ), color ), vec3( 2.2 ) );
	color = LINEAR_REC2020_TO_LINEAR_SRGB * color;
	color = clamp( color, 0.0, 1.0 );
	return color;
}
vec3 NeutralToneMapping( vec3 color ) {
	const float StartCompression = 0.8 - 0.04;
	const float Desaturation = 0.15;
	color *= toneMappingExposure;
	float x = min( color.r, min( color.g, color.b ) );
	float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
	color -= offset;
	float peak = max( color.r, max( color.g, color.b ) );
	if ( peak < StartCompression ) return color;
	float d = 1. - StartCompression;
	float newPeak = 1. - d * d / ( peak + d - StartCompression );
	color *= newPeak / peak;
	float g = 1. - 1. / ( Desaturation * ( peak - newPeak ) + 1. );
	return mix( color, vec3( newPeak ), g );
}
vec3 CustomToneMapping( vec3 color ) { return color; }`,transmission_fragment:`#ifdef USE_TRANSMISSION
	material.transmission = transmission;
	material.transmissionAlpha = 1.0;
	material.thickness = thickness;
	material.attenuationDistance = attenuationDistance;
	material.attenuationColor = attenuationColor;
	#ifdef USE_TRANSMISSIONMAP
		material.transmission *= texture2D( transmissionMap, vTransmissionMapUv ).r;
	#endif
	#ifdef USE_THICKNESSMAP
		material.thickness *= texture2D( thicknessMap, vThicknessMapUv ).g;
	#endif
	vec3 pos = vWorldPosition;
	vec3 v = normalize( cameraPosition - pos );
	vec3 n = inverseTransformDirection( normal, viewMatrix );
	vec4 transmitted = getIBLVolumeRefraction(
		n, v, material.roughness, material.diffuseColor, material.specularColor, material.specularF90,
		pos, modelMatrix, viewMatrix, projectionMatrix, material.dispersion, material.ior, material.thickness,
		material.attenuationColor, material.attenuationDistance );
	material.transmissionAlpha = mix( material.transmissionAlpha, transmitted.a, material.transmission );
	totalDiffuse = mix( totalDiffuse, transmitted.rgb, material.transmission );
#endif`,transmission_pars_fragment:`#ifdef USE_TRANSMISSION
	uniform float transmission;
	uniform float thickness;
	uniform float attenuationDistance;
	uniform vec3 attenuationColor;
	#ifdef USE_TRANSMISSIONMAP
		uniform sampler2D transmissionMap;
	#endif
	#ifdef USE_THICKNESSMAP
		uniform sampler2D thicknessMap;
	#endif
	uniform vec2 transmissionSamplerSize;
	uniform sampler2D transmissionSamplerMap;
	uniform mat4 modelMatrix;
	uniform mat4 projectionMatrix;
	varying vec3 vWorldPosition;
	float w0( float a ) {
		return ( 1.0 / 6.0 ) * ( a * ( a * ( - a + 3.0 ) - 3.0 ) + 1.0 );
	}
	float w1( float a ) {
		return ( 1.0 / 6.0 ) * ( a *  a * ( 3.0 * a - 6.0 ) + 4.0 );
	}
	float w2( float a ){
		return ( 1.0 / 6.0 ) * ( a * ( a * ( - 3.0 * a + 3.0 ) + 3.0 ) + 1.0 );
	}
	float w3( float a ) {
		return ( 1.0 / 6.0 ) * ( a * a * a );
	}
	float g0( float a ) {
		return w0( a ) + w1( a );
	}
	float g1( float a ) {
		return w2( a ) + w3( a );
	}
	float h0( float a ) {
		return - 1.0 + w1( a ) / ( w0( a ) + w1( a ) );
	}
	float h1( float a ) {
		return 1.0 + w3( a ) / ( w2( a ) + w3( a ) );
	}
	vec4 bicubic( sampler2D tex, vec2 uv, vec4 texelSize, float lod ) {
		uv = uv * texelSize.zw + 0.5;
		vec2 iuv = floor( uv );
		vec2 fuv = fract( uv );
		float g0x = g0( fuv.x );
		float g1x = g1( fuv.x );
		float h0x = h0( fuv.x );
		float h1x = h1( fuv.x );
		float h0y = h0( fuv.y );
		float h1y = h1( fuv.y );
		vec2 p0 = ( vec2( iuv.x + h0x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;
		vec2 p1 = ( vec2( iuv.x + h1x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;
		vec2 p2 = ( vec2( iuv.x + h0x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;
		vec2 p3 = ( vec2( iuv.x + h1x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;
		return g0( fuv.y ) * ( g0x * textureLod( tex, p0, lod ) + g1x * textureLod( tex, p1, lod ) ) +
			g1( fuv.y ) * ( g0x * textureLod( tex, p2, lod ) + g1x * textureLod( tex, p3, lod ) );
	}
	vec4 textureBicubic( sampler2D sampler, vec2 uv, float lod ) {
		vec2 fLodSize = vec2( textureSize( sampler, int( lod ) ) );
		vec2 cLodSize = vec2( textureSize( sampler, int( lod + 1.0 ) ) );
		vec2 fLodSizeInv = 1.0 / fLodSize;
		vec2 cLodSizeInv = 1.0 / cLodSize;
		vec4 fSample = bicubic( sampler, uv, vec4( fLodSizeInv, fLodSize ), floor( lod ) );
		vec4 cSample = bicubic( sampler, uv, vec4( cLodSizeInv, cLodSize ), ceil( lod ) );
		return mix( fSample, cSample, fract( lod ) );
	}
	vec3 getVolumeTransmissionRay( const in vec3 n, const in vec3 v, const in float thickness, const in float ior, const in mat4 modelMatrix ) {
		vec3 refractionVector = refract( - v, normalize( n ), 1.0 / ior );
		vec3 modelScale;
		modelScale.x = length( vec3( modelMatrix[ 0 ].xyz ) );
		modelScale.y = length( vec3( modelMatrix[ 1 ].xyz ) );
		modelScale.z = length( vec3( modelMatrix[ 2 ].xyz ) );
		return normalize( refractionVector ) * thickness * modelScale;
	}
	float applyIorToRoughness( const in float roughness, const in float ior ) {
		return roughness * clamp( ior * 2.0 - 2.0, 0.0, 1.0 );
	}
	vec4 getTransmissionSample( const in vec2 fragCoord, const in float roughness, const in float ior ) {
		float lod = log2( transmissionSamplerSize.x ) * applyIorToRoughness( roughness, ior );
		return textureBicubic( transmissionSamplerMap, fragCoord.xy, lod );
	}
	vec3 volumeAttenuation( const in float transmissionDistance, const in vec3 attenuationColor, const in float attenuationDistance ) {
		if ( isinf( attenuationDistance ) ) {
			return vec3( 1.0 );
		} else {
			vec3 attenuationCoefficient = -log( attenuationColor ) / attenuationDistance;
			vec3 transmittance = exp( - attenuationCoefficient * transmissionDistance );			return transmittance;
		}
	}
	vec4 getIBLVolumeRefraction( const in vec3 n, const in vec3 v, const in float roughness, const in vec3 diffuseColor,
		const in vec3 specularColor, const in float specularF90, const in vec3 position, const in mat4 modelMatrix,
		const in mat4 viewMatrix, const in mat4 projMatrix, const in float dispersion, const in float ior, const in float thickness,
		const in vec3 attenuationColor, const in float attenuationDistance ) {
		vec4 transmittedLight;
		vec3 transmittance;
		#ifdef USE_DISPERSION
			float halfSpread = ( ior - 1.0 ) * 0.025 * dispersion;
			vec3 iors = vec3( ior - halfSpread, ior, ior + halfSpread );
			for ( int i = 0; i < 3; i ++ ) {
				vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, iors[ i ], modelMatrix );
				vec3 refractedRayExit = position + transmissionRay;
		
				vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );
				vec2 refractionCoords = ndcPos.xy / ndcPos.w;
				refractionCoords += 1.0;
				refractionCoords /= 2.0;
		
				vec4 transmissionSample = getTransmissionSample( refractionCoords, roughness, iors[ i ] );
				transmittedLight[ i ] = transmissionSample[ i ];
				transmittedLight.a += transmissionSample.a;
				transmittance[ i ] = diffuseColor[ i ] * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance )[ i ];
			}
			transmittedLight.a /= 3.0;
		
		#else
		
			vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, ior, modelMatrix );
			vec3 refractedRayExit = position + transmissionRay;
			vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );
			vec2 refractionCoords = ndcPos.xy / ndcPos.w;
			refractionCoords += 1.0;
			refractionCoords /= 2.0;
			transmittedLight = getTransmissionSample( refractionCoords, roughness, ior );
			transmittance = diffuseColor * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance );
		
		#endif
		vec3 attenuatedColor = transmittance * transmittedLight.rgb;
		vec3 F = EnvironmentBRDF( n, v, specularColor, specularF90, roughness );
		float transmittanceFactor = ( transmittance.r + transmittance.g + transmittance.b ) / 3.0;
		return vec4( ( 1.0 - F ) * attenuatedColor, 1.0 - ( 1.0 - transmittedLight.a ) * transmittanceFactor );
	}
#endif`,uv_pars_fragment:`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	varying vec2 vUv;
#endif
#ifdef USE_MAP
	varying vec2 vMapUv;
#endif
#ifdef USE_ALPHAMAP
	varying vec2 vAlphaMapUv;
#endif
#ifdef USE_LIGHTMAP
	varying vec2 vLightMapUv;
#endif
#ifdef USE_AOMAP
	varying vec2 vAoMapUv;
#endif
#ifdef USE_BUMPMAP
	varying vec2 vBumpMapUv;
#endif
#ifdef USE_NORMALMAP
	varying vec2 vNormalMapUv;
#endif
#ifdef USE_EMISSIVEMAP
	varying vec2 vEmissiveMapUv;
#endif
#ifdef USE_METALNESSMAP
	varying vec2 vMetalnessMapUv;
#endif
#ifdef USE_ROUGHNESSMAP
	varying vec2 vRoughnessMapUv;
#endif
#ifdef USE_ANISOTROPYMAP
	varying vec2 vAnisotropyMapUv;
#endif
#ifdef USE_CLEARCOATMAP
	varying vec2 vClearcoatMapUv;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	varying vec2 vClearcoatNormalMapUv;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	varying vec2 vClearcoatRoughnessMapUv;
#endif
#ifdef USE_IRIDESCENCEMAP
	varying vec2 vIridescenceMapUv;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	varying vec2 vIridescenceThicknessMapUv;
#endif
#ifdef USE_SHEEN_COLORMAP
	varying vec2 vSheenColorMapUv;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	varying vec2 vSheenRoughnessMapUv;
#endif
#ifdef USE_SPECULARMAP
	varying vec2 vSpecularMapUv;
#endif
#ifdef USE_SPECULAR_COLORMAP
	varying vec2 vSpecularColorMapUv;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	varying vec2 vSpecularIntensityMapUv;
#endif
#ifdef USE_TRANSMISSIONMAP
	uniform mat3 transmissionMapTransform;
	varying vec2 vTransmissionMapUv;
#endif
#ifdef USE_THICKNESSMAP
	uniform mat3 thicknessMapTransform;
	varying vec2 vThicknessMapUv;
#endif`,uv_pars_vertex:`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	varying vec2 vUv;
#endif
#ifdef USE_MAP
	uniform mat3 mapTransform;
	varying vec2 vMapUv;
#endif
#ifdef USE_ALPHAMAP
	uniform mat3 alphaMapTransform;
	varying vec2 vAlphaMapUv;
#endif
#ifdef USE_LIGHTMAP
	uniform mat3 lightMapTransform;
	varying vec2 vLightMapUv;
#endif
#ifdef USE_AOMAP
	uniform mat3 aoMapTransform;
	varying vec2 vAoMapUv;
#endif
#ifdef USE_BUMPMAP
	uniform mat3 bumpMapTransform;
	varying vec2 vBumpMapUv;
#endif
#ifdef USE_NORMALMAP
	uniform mat3 normalMapTransform;
	varying vec2 vNormalMapUv;
#endif
#ifdef USE_DISPLACEMENTMAP
	uniform mat3 displacementMapTransform;
	varying vec2 vDisplacementMapUv;
#endif
#ifdef USE_EMISSIVEMAP
	uniform mat3 emissiveMapTransform;
	varying vec2 vEmissiveMapUv;
#endif
#ifdef USE_METALNESSMAP
	uniform mat3 metalnessMapTransform;
	varying vec2 vMetalnessMapUv;
#endif
#ifdef USE_ROUGHNESSMAP
	uniform mat3 roughnessMapTransform;
	varying vec2 vRoughnessMapUv;
#endif
#ifdef USE_ANISOTROPYMAP
	uniform mat3 anisotropyMapTransform;
	varying vec2 vAnisotropyMapUv;
#endif
#ifdef USE_CLEARCOATMAP
	uniform mat3 clearcoatMapTransform;
	varying vec2 vClearcoatMapUv;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform mat3 clearcoatNormalMapTransform;
	varying vec2 vClearcoatNormalMapUv;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform mat3 clearcoatRoughnessMapTransform;
	varying vec2 vClearcoatRoughnessMapUv;
#endif
#ifdef USE_SHEEN_COLORMAP
	uniform mat3 sheenColorMapTransform;
	varying vec2 vSheenColorMapUv;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	uniform mat3 sheenRoughnessMapTransform;
	varying vec2 vSheenRoughnessMapUv;
#endif
#ifdef USE_IRIDESCENCEMAP
	uniform mat3 iridescenceMapTransform;
	varying vec2 vIridescenceMapUv;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform mat3 iridescenceThicknessMapTransform;
	varying vec2 vIridescenceThicknessMapUv;
#endif
#ifdef USE_SPECULARMAP
	uniform mat3 specularMapTransform;
	varying vec2 vSpecularMapUv;
#endif
#ifdef USE_SPECULAR_COLORMAP
	uniform mat3 specularColorMapTransform;
	varying vec2 vSpecularColorMapUv;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	uniform mat3 specularIntensityMapTransform;
	varying vec2 vSpecularIntensityMapUv;
#endif
#ifdef USE_TRANSMISSIONMAP
	uniform mat3 transmissionMapTransform;
	varying vec2 vTransmissionMapUv;
#endif
#ifdef USE_THICKNESSMAP
	uniform mat3 thicknessMapTransform;
	varying vec2 vThicknessMapUv;
#endif`,uv_vertex:`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	vUv = vec3( uv, 1 ).xy;
#endif
#ifdef USE_MAP
	vMapUv = ( mapTransform * vec3( MAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ALPHAMAP
	vAlphaMapUv = ( alphaMapTransform * vec3( ALPHAMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_LIGHTMAP
	vLightMapUv = ( lightMapTransform * vec3( LIGHTMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_AOMAP
	vAoMapUv = ( aoMapTransform * vec3( AOMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_BUMPMAP
	vBumpMapUv = ( bumpMapTransform * vec3( BUMPMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_NORMALMAP
	vNormalMapUv = ( normalMapTransform * vec3( NORMALMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_DISPLACEMENTMAP
	vDisplacementMapUv = ( displacementMapTransform * vec3( DISPLACEMENTMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_EMISSIVEMAP
	vEmissiveMapUv = ( emissiveMapTransform * vec3( EMISSIVEMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_METALNESSMAP
	vMetalnessMapUv = ( metalnessMapTransform * vec3( METALNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ROUGHNESSMAP
	vRoughnessMapUv = ( roughnessMapTransform * vec3( ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ANISOTROPYMAP
	vAnisotropyMapUv = ( anisotropyMapTransform * vec3( ANISOTROPYMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOATMAP
	vClearcoatMapUv = ( clearcoatMapTransform * vec3( CLEARCOATMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	vClearcoatNormalMapUv = ( clearcoatNormalMapTransform * vec3( CLEARCOAT_NORMALMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	vClearcoatRoughnessMapUv = ( clearcoatRoughnessMapTransform * vec3( CLEARCOAT_ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_IRIDESCENCEMAP
	vIridescenceMapUv = ( iridescenceMapTransform * vec3( IRIDESCENCEMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	vIridescenceThicknessMapUv = ( iridescenceThicknessMapTransform * vec3( IRIDESCENCE_THICKNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SHEEN_COLORMAP
	vSheenColorMapUv = ( sheenColorMapTransform * vec3( SHEEN_COLORMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	vSheenRoughnessMapUv = ( sheenRoughnessMapTransform * vec3( SHEEN_ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULARMAP
	vSpecularMapUv = ( specularMapTransform * vec3( SPECULARMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULAR_COLORMAP
	vSpecularColorMapUv = ( specularColorMapTransform * vec3( SPECULAR_COLORMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	vSpecularIntensityMapUv = ( specularIntensityMapTransform * vec3( SPECULAR_INTENSITYMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_TRANSMISSIONMAP
	vTransmissionMapUv = ( transmissionMapTransform * vec3( TRANSMISSIONMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_THICKNESSMAP
	vThicknessMapUv = ( thicknessMapTransform * vec3( THICKNESSMAP_UV, 1 ) ).xy;
#endif`,worldpos_vertex:`#if defined( USE_ENVMAP ) || defined( DISTANCE ) || defined ( USE_SHADOWMAP ) || defined ( USE_TRANSMISSION ) || NUM_SPOT_LIGHT_COORDS > 0
	vec4 worldPosition = vec4( transformed, 1.0 );
	#ifdef USE_BATCHING
		worldPosition = batchingMatrix * worldPosition;
	#endif
	#ifdef USE_INSTANCING
		worldPosition = instanceMatrix * worldPosition;
	#endif
	worldPosition = modelMatrix * worldPosition;
#endif`,background_vert:`varying vec2 vUv;
uniform mat3 uvTransform;
void main() {
	vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	gl_Position = vec4( position.xy, 1.0, 1.0 );
}`,background_frag:`uniform sampler2D t2D;
uniform float backgroundIntensity;
varying vec2 vUv;
void main() {
	vec4 texColor = texture2D( t2D, vUv );
	#ifdef DECODE_VIDEO_TEXTURE
		texColor = vec4( mix( pow( texColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), texColor.rgb * 0.0773993808, vec3( lessThanEqual( texColor.rgb, vec3( 0.04045 ) ) ) ), texColor.w );
	#endif
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,backgroundCube_vert:`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`,backgroundCube_frag:`#ifdef ENVMAP_TYPE_CUBE
	uniform samplerCube envMap;
#elif defined( ENVMAP_TYPE_CUBE_UV )
	uniform sampler2D envMap;
#endif
uniform float flipEnvMap;
uniform float backgroundBlurriness;
uniform float backgroundIntensity;
uniform mat3 backgroundRotation;
varying vec3 vWorldDirection;
#include <cube_uv_reflection_fragment>
void main() {
	#ifdef ENVMAP_TYPE_CUBE
		vec4 texColor = textureCube( envMap, backgroundRotation * vec3( flipEnvMap * vWorldDirection.x, vWorldDirection.yz ) );
	#elif defined( ENVMAP_TYPE_CUBE_UV )
		vec4 texColor = textureCubeUV( envMap, backgroundRotation * vWorldDirection, backgroundBlurriness );
	#else
		vec4 texColor = vec4( 0.0, 0.0, 0.0, 1.0 );
	#endif
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,cube_vert:`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`,cube_frag:`uniform samplerCube tCube;
uniform float tFlip;
uniform float opacity;
varying vec3 vWorldDirection;
void main() {
	vec4 texColor = textureCube( tCube, vec3( tFlip * vWorldDirection.x, vWorldDirection.yz ) );
	gl_FragColor = texColor;
	gl_FragColor.a *= opacity;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,depth_vert:`#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
varying vec2 vHighPrecisionZW;
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <skinbase_vertex>
	#include <morphinstance_vertex>
	#ifdef USE_DISPLACEMENTMAP
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vHighPrecisionZW = gl_Position.zw;
}`,depth_frag:`#if DEPTH_PACKING == 3200
	uniform float opacity;
#endif
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
varying vec2 vHighPrecisionZW;
void main() {
	vec4 diffuseColor = vec4( 1.0 );
	#include <clipping_planes_fragment>
	#if DEPTH_PACKING == 3200
		diffuseColor.a = opacity;
	#endif
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <logdepthbuf_fragment>
	float fragCoordZ = 0.5 * vHighPrecisionZW[0] / vHighPrecisionZW[1] + 0.5;
	#if DEPTH_PACKING == 3200
		gl_FragColor = vec4( vec3( 1.0 - fragCoordZ ), opacity );
	#elif DEPTH_PACKING == 3201
		gl_FragColor = packDepthToRGBA( fragCoordZ );
	#elif DEPTH_PACKING == 3202
		gl_FragColor = vec4( packDepthToRGB( fragCoordZ ), 1.0 );
	#elif DEPTH_PACKING == 3203
		gl_FragColor = vec4( packDepthToRG( fragCoordZ ), 0.0, 1.0 );
	#endif
}`,distanceRGBA_vert:`#define DISTANCE
varying vec3 vWorldPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <skinbase_vertex>
	#include <morphinstance_vertex>
	#ifdef USE_DISPLACEMENTMAP
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <worldpos_vertex>
	#include <clipping_planes_vertex>
	vWorldPosition = worldPosition.xyz;
}`,distanceRGBA_frag:`#define DISTANCE
uniform vec3 referencePosition;
uniform float nearDistance;
uniform float farDistance;
varying vec3 vWorldPosition;
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <clipping_planes_pars_fragment>
void main () {
	vec4 diffuseColor = vec4( 1.0 );
	#include <clipping_planes_fragment>
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	float dist = length( vWorldPosition - referencePosition );
	dist = ( dist - nearDistance ) / ( farDistance - nearDistance );
	dist = saturate( dist );
	gl_FragColor = packDepthToRGBA( dist );
}`,equirect_vert:`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
}`,equirect_frag:`uniform sampler2D tEquirect;
varying vec3 vWorldDirection;
#include <common>
void main() {
	vec3 direction = normalize( vWorldDirection );
	vec2 sampleUV = equirectUv( direction );
	gl_FragColor = texture2D( tEquirect, sampleUV );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,linedashed_vert:`uniform float scale;
attribute float lineDistance;
varying float vLineDistance;
#include <common>
#include <uv_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	vLineDistance = scale * lineDistance;
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`,linedashed_frag:`uniform vec3 diffuse;
uniform float opacity;
uniform float dashSize;
uniform float totalSize;
varying float vLineDistance;
#include <common>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	if ( mod( vLineDistance, totalSize ) > dashSize ) {
		discard;
	}
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`,meshbasic_vert:`#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#if defined ( USE_ENVMAP ) || defined ( USE_SKINNING )
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinbase_vertex>
		#include <skinnormal_vertex>
		#include <defaultnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <fog_vertex>
}`,meshbasic_frag:`uniform vec3 diffuse;
uniform float opacity;
#ifndef FLAT_SHADED
	varying vec3 vNormal;
#endif
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		reflectedLight.indirectDiffuse += lightMapTexel.rgb * lightMapIntensity * RECIPROCAL_PI;
	#else
		reflectedLight.indirectDiffuse += vec3( 1.0 );
	#endif
	#include <aomap_fragment>
	reflectedLight.indirectDiffuse *= diffuseColor.rgb;
	vec3 outgoingLight = reflectedLight.indirectDiffuse;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,meshlambert_vert:`#define LAMBERT
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,meshlambert_frag:`#define LAMBERT
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_lambert_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_lambert_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,meshmatcap_vert:`#define MATCAP
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <color_pars_vertex>
#include <displacementmap_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
	vViewPosition = - mvPosition.xyz;
}`,meshmatcap_frag:`#define MATCAP
uniform vec3 diffuse;
uniform float opacity;
uniform sampler2D matcap;
varying vec3 vViewPosition;
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <normal_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	vec3 viewDir = normalize( vViewPosition );
	vec3 x = normalize( vec3( viewDir.z, 0.0, - viewDir.x ) );
	vec3 y = cross( viewDir, x );
	vec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5;
	#ifdef USE_MATCAP
		vec4 matcapColor = texture2D( matcap, uv );
	#else
		vec4 matcapColor = vec4( vec3( mix( 0.2, 0.8, uv.y ) ), 1.0 );
	#endif
	vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,meshnormal_vert:`#define NORMAL
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	varying vec3 vViewPosition;
#endif
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	vViewPosition = - mvPosition.xyz;
#endif
}`,meshnormal_frag:`#define NORMAL
uniform float opacity;
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	varying vec3 vViewPosition;
#endif
#include <packing>
#include <uv_pars_fragment>
#include <normal_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( 0.0, 0.0, 0.0, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	gl_FragColor = vec4( packNormalToRGB( normal ), diffuseColor.a );
	#ifdef OPAQUE
		gl_FragColor.a = 1.0;
	#endif
}`,meshphong_vert:`#define PHONG
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,meshphong_frag:`#define PHONG
uniform vec3 diffuse;
uniform vec3 emissive;
uniform vec3 specular;
uniform float shininess;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_phong_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_phong_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,meshphysical_vert:`#define STANDARD
varying vec3 vViewPosition;
#ifdef USE_TRANSMISSION
	varying vec3 vWorldPosition;
#endif
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
#ifdef USE_TRANSMISSION
	vWorldPosition = worldPosition.xyz;
#endif
}`,meshphysical_frag:`#define STANDARD
#ifdef PHYSICAL
	#define IOR
	#define USE_SPECULAR
#endif
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float roughness;
uniform float metalness;
uniform float opacity;
#ifdef IOR
	uniform float ior;
#endif
#ifdef USE_SPECULAR
	uniform float specularIntensity;
	uniform vec3 specularColor;
	#ifdef USE_SPECULAR_COLORMAP
		uniform sampler2D specularColorMap;
	#endif
	#ifdef USE_SPECULAR_INTENSITYMAP
		uniform sampler2D specularIntensityMap;
	#endif
#endif
#ifdef USE_CLEARCOAT
	uniform float clearcoat;
	uniform float clearcoatRoughness;
#endif
#ifdef USE_DISPERSION
	uniform float dispersion;
#endif
#ifdef USE_IRIDESCENCE
	uniform float iridescence;
	uniform float iridescenceIOR;
	uniform float iridescenceThicknessMinimum;
	uniform float iridescenceThicknessMaximum;
#endif
#ifdef USE_SHEEN
	uniform vec3 sheenColor;
	uniform float sheenRoughness;
	#ifdef USE_SHEEN_COLORMAP
		uniform sampler2D sheenColorMap;
	#endif
	#ifdef USE_SHEEN_ROUGHNESSMAP
		uniform sampler2D sheenRoughnessMap;
	#endif
#endif
#ifdef USE_ANISOTROPY
	uniform vec2 anisotropyVector;
	#ifdef USE_ANISOTROPYMAP
		uniform sampler2D anisotropyMap;
	#endif
#endif
varying vec3 vViewPosition;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <iridescence_fragment>
#include <cube_uv_reflection_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_physical_pars_fragment>
#include <fog_pars_fragment>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_physical_pars_fragment>
#include <transmission_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <clearcoat_pars_fragment>
#include <iridescence_pars_fragment>
#include <roughnessmap_pars_fragment>
#include <metalnessmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <roughnessmap_fragment>
	#include <metalnessmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <clearcoat_normal_fragment_begin>
	#include <clearcoat_normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_physical_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 totalDiffuse = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;
	vec3 totalSpecular = reflectedLight.directSpecular + reflectedLight.indirectSpecular;
	#include <transmission_fragment>
	vec3 outgoingLight = totalDiffuse + totalSpecular + totalEmissiveRadiance;
	#ifdef USE_SHEEN
		float sheenEnergyComp = 1.0 - 0.157 * max3( material.sheenColor );
		outgoingLight = outgoingLight * sheenEnergyComp + sheenSpecularDirect + sheenSpecularIndirect;
	#endif
	#ifdef USE_CLEARCOAT
		float dotNVcc = saturate( dot( geometryClearcoatNormal, geometryViewDir ) );
		vec3 Fcc = F_Schlick( material.clearcoatF0, material.clearcoatF90, dotNVcc );
		outgoingLight = outgoingLight * ( 1.0 - material.clearcoat * Fcc ) + ( clearcoatSpecularDirect + clearcoatSpecularIndirect ) * material.clearcoat;
	#endif
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,meshtoon_vert:`#define TOON
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,meshtoon_frag:`#define TOON
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <gradientmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_toon_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_toon_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,points_vert:`uniform float size;
uniform float scale;
#include <common>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
#ifdef USE_POINTS_UV
	varying vec2 vUv;
	uniform mat3 uvTransform;
#endif
void main() {
	#ifdef USE_POINTS_UV
		vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	#endif
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	gl_PointSize = size;
	#ifdef USE_SIZEATTENUATION
		bool isPerspective = isPerspectiveMatrix( projectionMatrix );
		if ( isPerspective ) gl_PointSize *= ( scale / - mvPosition.z );
	#endif
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <fog_vertex>
}`,points_frag:`uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <color_pars_fragment>
#include <map_particle_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_particle_fragment>
	#include <color_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`,shadow_vert:`#include <common>
#include <batching_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <shadowmap_pars_vertex>
void main() {
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,shadow_frag:`uniform vec3 color;
uniform float opacity;
#include <common>
#include <packing>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <logdepthbuf_pars_fragment>
#include <shadowmap_pars_fragment>
#include <shadowmask_pars_fragment>
void main() {
	#include <logdepthbuf_fragment>
	gl_FragColor = vec4( color, opacity * ( 1.0 - getShadowMask() ) );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
}`,sprite_vert:`uniform float rotation;
uniform vec2 center;
#include <common>
#include <uv_pars_vertex>
#include <fog_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	vec4 mvPosition = modelViewMatrix[ 3 ];
	vec2 scale = vec2( length( modelMatrix[ 0 ].xyz ), length( modelMatrix[ 1 ].xyz ) );
	#ifndef USE_SIZEATTENUATION
		bool isPerspective = isPerspectiveMatrix( projectionMatrix );
		if ( isPerspective ) scale *= - mvPosition.z;
	#endif
	vec2 alignedPosition = ( position.xy - ( center - vec2( 0.5 ) ) ) * scale;
	vec2 rotatedPosition;
	rotatedPosition.x = cos( rotation ) * alignedPosition.x - sin( rotation ) * alignedPosition.y;
	rotatedPosition.y = sin( rotation ) * alignedPosition.x + cos( rotation ) * alignedPosition.y;
	mvPosition.xy += rotatedPosition;
	gl_Position = projectionMatrix * mvPosition;
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`,sprite_frag:`uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
}`},K={common:{diffuse:{value:new W(16777215)},opacity:{value:1},map:{value:null},mapTransform:{value:new z},alphaMap:{value:null},alphaMapTransform:{value:new z},alphaTest:{value:0}},specularmap:{specularMap:{value:null},specularMapTransform:{value:new z}},envmap:{envMap:{value:null},envMapRotation:{value:new z},flipEnvMap:{value:-1},reflectivity:{value:1},ior:{value:1.5},refractionRatio:{value:.98}},aomap:{aoMap:{value:null},aoMapIntensity:{value:1},aoMapTransform:{value:new z}},lightmap:{lightMap:{value:null},lightMapIntensity:{value:1},lightMapTransform:{value:new z}},bumpmap:{bumpMap:{value:null},bumpMapTransform:{value:new z},bumpScale:{value:1}},normalmap:{normalMap:{value:null},normalMapTransform:{value:new z},normalScale:{value:new R(1,1)}},displacementmap:{displacementMap:{value:null},displacementMapTransform:{value:new z},displacementScale:{value:1},displacementBias:{value:0}},emissivemap:{emissiveMap:{value:null},emissiveMapTransform:{value:new z}},metalnessmap:{metalnessMap:{value:null},metalnessMapTransform:{value:new z}},roughnessmap:{roughnessMap:{value:null},roughnessMapTransform:{value:new z}},gradientmap:{gradientMap:{value:null}},fog:{fogDensity:{value:25e-5},fogNear:{value:1},fogFar:{value:2e3},fogColor:{value:new W(16777215)}},lights:{ambientLightColor:{value:[]},lightProbe:{value:[]},directionalLights:{value:[],properties:{direction:{},color:{}}},directionalLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{}}},directionalShadowMap:{value:[]},directionalShadowMatrix:{value:[]},spotLights:{value:[],properties:{color:{},position:{},direction:{},distance:{},coneCos:{},penumbraCos:{},decay:{}}},spotLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{}}},spotLightMap:{value:[]},spotShadowMap:{value:[]},spotLightMatrix:{value:[]},pointLights:{value:[],properties:{color:{},position:{},decay:{},distance:{}}},pointLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{},shadowCameraNear:{},shadowCameraFar:{}}},pointShadowMap:{value:[]},pointShadowMatrix:{value:[]},hemisphereLights:{value:[],properties:{direction:{},skyColor:{},groundColor:{}}},rectAreaLights:{value:[],properties:{color:{},position:{},width:{},height:{}}},ltc_1:{value:null},ltc_2:{value:null}},points:{diffuse:{value:new W(16777215)},opacity:{value:1},size:{value:1},scale:{value:1},map:{value:null},alphaMap:{value:null},alphaMapTransform:{value:new z},alphaTest:{value:0},uvTransform:{value:new z}},sprite:{diffuse:{value:new W(16777215)},opacity:{value:1},center:{value:new R(.5,.5)},rotation:{value:0},map:{value:null},mapTransform:{value:new z},alphaMap:{value:null},alphaMapTransform:{value:new z},alphaTest:{value:0}}},xi={basic:{uniforms:Jr([K.common,K.specularmap,K.envmap,K.aomap,K.lightmap,K.fog]),vertexShader:G.meshbasic_vert,fragmentShader:G.meshbasic_frag},lambert:{uniforms:Jr([K.common,K.specularmap,K.envmap,K.aomap,K.lightmap,K.emissivemap,K.bumpmap,K.normalmap,K.displacementmap,K.fog,K.lights,{emissive:{value:new W(0)}}]),vertexShader:G.meshlambert_vert,fragmentShader:G.meshlambert_frag},phong:{uniforms:Jr([K.common,K.specularmap,K.envmap,K.aomap,K.lightmap,K.emissivemap,K.bumpmap,K.normalmap,K.displacementmap,K.fog,K.lights,{emissive:{value:new W(0)},specular:{value:new W(1118481)},shininess:{value:30}}]),vertexShader:G.meshphong_vert,fragmentShader:G.meshphong_frag},standard:{uniforms:Jr([K.common,K.envmap,K.aomap,K.lightmap,K.emissivemap,K.bumpmap,K.normalmap,K.displacementmap,K.roughnessmap,K.metalnessmap,K.fog,K.lights,{emissive:{value:new W(0)},roughness:{value:1},metalness:{value:0},envMapIntensity:{value:1}}]),vertexShader:G.meshphysical_vert,fragmentShader:G.meshphysical_frag},toon:{uniforms:Jr([K.common,K.aomap,K.lightmap,K.emissivemap,K.bumpmap,K.normalmap,K.displacementmap,K.gradientmap,K.fog,K.lights,{emissive:{value:new W(0)}}]),vertexShader:G.meshtoon_vert,fragmentShader:G.meshtoon_frag},matcap:{uniforms:Jr([K.common,K.bumpmap,K.normalmap,K.displacementmap,K.fog,{matcap:{value:null}}]),vertexShader:G.meshmatcap_vert,fragmentShader:G.meshmatcap_frag},points:{uniforms:Jr([K.points,K.fog]),vertexShader:G.points_vert,fragmentShader:G.points_frag},dashed:{uniforms:Jr([K.common,K.fog,{scale:{value:1},dashSize:{value:1},totalSize:{value:2}}]),vertexShader:G.linedashed_vert,fragmentShader:G.linedashed_frag},depth:{uniforms:Jr([K.common,K.displacementmap]),vertexShader:G.depth_vert,fragmentShader:G.depth_frag},normal:{uniforms:Jr([K.common,K.bumpmap,K.normalmap,K.displacementmap,{opacity:{value:1}}]),vertexShader:G.meshnormal_vert,fragmentShader:G.meshnormal_frag},sprite:{uniforms:Jr([K.sprite,K.fog]),vertexShader:G.sprite_vert,fragmentShader:G.sprite_frag},background:{uniforms:{uvTransform:{value:new z},t2D:{value:null},backgroundIntensity:{value:1}},vertexShader:G.background_vert,fragmentShader:G.background_frag},backgroundCube:{uniforms:{envMap:{value:null},flipEnvMap:{value:-1},backgroundBlurriness:{value:0},backgroundIntensity:{value:1},backgroundRotation:{value:new z}},vertexShader:G.backgroundCube_vert,fragmentShader:G.backgroundCube_frag},cube:{uniforms:{tCube:{value:null},tFlip:{value:-1},opacity:{value:1}},vertexShader:G.cube_vert,fragmentShader:G.cube_frag},equirect:{uniforms:{tEquirect:{value:null}},vertexShader:G.equirect_vert,fragmentShader:G.equirect_frag},distanceRGBA:{uniforms:Jr([K.common,K.displacementmap,{referencePosition:{value:new H},nearDistance:{value:1},farDistance:{value:1e3}}]),vertexShader:G.distanceRGBA_vert,fragmentShader:G.distanceRGBA_frag},shadow:{uniforms:Jr([K.lights,K.fog,{color:{value:new W(0)},opacity:{value:1}}]),vertexShader:G.shadow_vert,fragmentShader:G.shadow_frag}};xi.physical={uniforms:Jr([xi.standard.uniforms,{clearcoat:{value:0},clearcoatMap:{value:null},clearcoatMapTransform:{value:new z},clearcoatNormalMap:{value:null},clearcoatNormalMapTransform:{value:new z},clearcoatNormalScale:{value:new R(1,1)},clearcoatRoughness:{value:0},clearcoatRoughnessMap:{value:null},clearcoatRoughnessMapTransform:{value:new z},dispersion:{value:0},iridescence:{value:0},iridescenceMap:{value:null},iridescenceMapTransform:{value:new z},iridescenceIOR:{value:1.3},iridescenceThicknessMinimum:{value:100},iridescenceThicknessMaximum:{value:400},iridescenceThicknessMap:{value:null},iridescenceThicknessMapTransform:{value:new z},sheen:{value:0},sheenColor:{value:new W(0)},sheenColorMap:{value:null},sheenColorMapTransform:{value:new z},sheenRoughness:{value:1},sheenRoughnessMap:{value:null},sheenRoughnessMapTransform:{value:new z},transmission:{value:0},transmissionMap:{value:null},transmissionMapTransform:{value:new z},transmissionSamplerSize:{value:new R},transmissionSamplerMap:{value:null},thickness:{value:0},thicknessMap:{value:null},thicknessMapTransform:{value:new z},attenuationDistance:{value:0},attenuationColor:{value:new W(0)},specularColor:{value:new W(1,1,1)},specularColorMap:{value:null},specularColorMapTransform:{value:new z},specularIntensity:{value:1},specularIntensityMap:{value:null},specularIntensityMapTransform:{value:new z},anisotropyVector:{value:new R},anisotropyMap:{value:null},anisotropyMapTransform:{value:new z}}]),vertexShader:G.meshphysical_vert,fragmentShader:G.meshphysical_frag};var Si={r:0,b:0,g:0},Ci=new Mn,wi=new U;function Ti(e,t,n,r,i,a,o){let s=new W(0),c=a===!0?0:1,l,u,d=null,f=0,p=null;function m(e){let r=e.isScene===!0?e.background:null;return r&&r.isTexture&&(r=(e.backgroundBlurriness>0?n:t).get(r)),r}function h(t){let n=!1,i=m(t);i===null?_(s,c):i&&i.isColor&&(_(i,1),n=!0);let a=e.xr.getEnvironmentBlendMode();a===`additive`?r.buffers.color.setClear(0,0,0,1,o):a===`alpha-blend`&&r.buffers.color.setClear(0,0,0,0,o),(e.autoClear||n)&&(r.buffers.depth.setTest(!0),r.buffers.depth.setMask(!0),r.buffers.color.setMask(!0),e.clear(e.autoClearColor,e.autoClearDepth,e.autoClearStencil))}function g(t,n){let r=m(n);r&&(r.isCubeTexture||r.mapping===306)?(u===void 0&&(u=new Ur(new Kr(1,1,1),new ei({name:`BackgroundCubeMaterial`,uniforms:qr(xi.backgroundCube.uniforms),vertexShader:xi.backgroundCube.vertexShader,fragmentShader:xi.backgroundCube.fragmentShader,side:1,depthTest:!1,depthWrite:!1,fog:!1})),u.geometry.deleteAttribute(`normal`),u.geometry.deleteAttribute(`uv`),u.onBeforeRender=function(e,t,n){this.matrixWorld.copyPosition(n.matrixWorld)},Object.defineProperty(u.material,"envMap",{get:function(){return this.uniforms.envMap.value}}),i.update(u)),Ci.copy(n.backgroundRotation),Ci.x*=-1,Ci.y*=-1,Ci.z*=-1,r.isCubeTexture&&r.isRenderTargetTexture===!1&&(Ci.y*=-1,Ci.z*=-1),u.material.uniforms.envMap.value=r,u.material.uniforms.flipEnvMap.value=r.isCubeTexture&&r.isRenderTargetTexture===!1?-1:1,u.material.uniforms.backgroundBlurriness.value=n.backgroundBlurriness,u.material.uniforms.backgroundIntensity.value=n.backgroundIntensity,u.material.uniforms.backgroundRotation.value.setFromMatrix4(wi.makeRotationFromEuler(Ci)),u.material.toneMapped=Ot.getTransfer(r.colorSpace)!==Ve,(d!==r||f!==r.version||p!==e.toneMapping)&&(u.material.needsUpdate=!0,d=r,f=r.version,p=e.toneMapping),u.layers.enableAll(),t.unshift(u,u.geometry,u.material,0,0,null)):r&&r.isTexture&&(l===void 0&&(l=new Ur(new bi(2,2),new ei({name:`BackgroundMaterial`,uniforms:qr(xi.background.uniforms),vertexShader:xi.background.vertexShader,fragmentShader:xi.background.fragmentShader,side:0,depthTest:!1,depthWrite:!1,fog:!1})),l.geometry.deleteAttribute(`normal`),Object.defineProperty(l.material,"map",{get:function(){return this.uniforms.t2D.value}}),i.update(l)),l.material.uniforms.t2D.value=r,l.material.uniforms.backgroundIntensity.value=n.backgroundIntensity,l.material.toneMapped=Ot.getTransfer(r.colorSpace)!==Ve,r.matrixAutoUpdate===!0&&r.updateMatrix(),l.material.uniforms.uvTransform.value.copy(r.matrix),(d!==r||f!==r.version||p!==e.toneMapping)&&(l.material.needsUpdate=!0,d=r,f=r.version,p=e.toneMapping),l.layers.enableAll(),t.unshift(l,l.geometry,l.material,0,0,null))}function _(t,n){t.getRGB(Si,Xr(e)),r.buffers.color.setClear(Si.r,Si.g,Si.b,n,o)}return{getClearColor:function(){return s},setClearColor:function(e,t=1){s.set(e),c=t,_(s,c)},getClearAlpha:function(){return c},setClearAlpha:function(e){c=e,_(s,c)},render:h,addToRenderList:g}}function Ei(e,t){let n=e.getParameter(e.MAX_VERTEX_ATTRIBS),r={},i=f(null),a=i,o=!1;function s(n,r,i,s,c){let u=!1,f=d(s,i,r);a!==f&&(a=f,l(a.object)),u=p(n,s,i,c),u&&m(n,s,i,c),c!==null&&t.update(c,e.ELEMENT_ARRAY_BUFFER),(u||o)&&(o=!1,b(n,r,i,s),c!==null&&e.bindBuffer(e.ELEMENT_ARRAY_BUFFER,t.get(c).buffer))}function c(){return e.createVertexArray()}function l(t){return e.bindVertexArray(t)}function u(t){return e.deleteVertexArray(t)}function d(e,t,n){let i=n.wireframe===!0,a=r[e.id];a===void 0&&(a={},r[e.id]=a);let o=a[t.id];o===void 0&&(o={},a[t.id]=o);let s=o[i];return s===void 0&&(s=f(c()),o[i]=s),s}function f(e){let t=[],r=[],i=[];for(let e=0;e<n;e++)t[e]=0,r[e]=0,i[e]=0;return{geometry:null,program:null,wireframe:!1,newAttributes:t,enabledAttributes:r,attributeDivisors:i,object:e,attributes:{},index:null}}function p(e,t,n,r){let i=a.attributes,o=t.attributes,s=0,c=n.getAttributes();for(let t in c)if(c[t].location>=0){let n=i[t],r=o[t];if(r===void 0&&(t===`instanceMatrix`&&e.instanceMatrix&&(r=e.instanceMatrix),t===`instanceColor`&&e.instanceColor&&(r=e.instanceColor)),n===void 0||n.attribute!==r||r&&n.data!==r.data)return!0;s++}return a.attributesNum!==s||a.index!==r}function m(e,t,n,r){let i={},o=t.attributes,s=0,c=n.getAttributes();for(let t in c)if(c[t].location>=0){let n=o[t];n===void 0&&(t===`instanceMatrix`&&e.instanceMatrix&&(n=e.instanceMatrix),t===`instanceColor`&&e.instanceColor&&(n=e.instanceColor));let r={};r.attribute=n,n&&n.data&&(r.data=n.data),i[t]=r,s++}a.attributes=i,a.attributesNum=s,a.index=r}function h(){let e=a.newAttributes;for(let t=0,n=e.length;t<n;t++)e[t]=0}function g(e){_(e,0)}function _(t,n){let r=a.newAttributes,i=a.enabledAttributes,o=a.attributeDivisors;r[t]=1,i[t]===0&&(e.enableVertexAttribArray(t),i[t]=1),o[t]!==n&&(e.vertexAttribDivisor(t,n),o[t]=n)}function v(){let t=a.newAttributes,n=a.enabledAttributes;for(let r=0,i=n.length;r<i;r++)n[r]!==t[r]&&(e.disableVertexAttribArray(r),n[r]=0)}function y(t,n,r,i,a,o,s){s===!0?e.vertexAttribIPointer(t,n,r,a,o):e.vertexAttribPointer(t,n,r,i,a,o)}function b(n,r,i,a){h();let o=a.attributes,s=i.getAttributes(),c=r.defaultAttributeValues;for(let r in s){let i=s[r];if(i.location>=0){let s=o[r];if(s===void 0&&(r===`instanceMatrix`&&n.instanceMatrix&&(s=n.instanceMatrix),r===`instanceColor`&&n.instanceColor&&(s=n.instanceColor)),s!==void 0){let r=s.normalized,o=s.itemSize,c=t.get(s);if(c===void 0)continue;let l=c.buffer,u=c.type,d=c.bytesPerElement,f=u===e.INT||u===e.UNSIGNED_INT||s.gpuType===1013;if(s.isInterleavedBufferAttribute){let t=s.data,c=t.stride,p=s.offset;if(t.isInstancedInterleavedBuffer){for(let e=0;e<i.locationSize;e++)_(i.location+e,t.meshPerAttribute);n.isInstancedMesh!==!0&&a._maxInstanceCount===void 0&&(a._maxInstanceCount=t.meshPerAttribute*t.count)}else for(let e=0;e<i.locationSize;e++)g(i.location+e);e.bindBuffer(e.ARRAY_BUFFER,l);for(let e=0;e<i.locationSize;e++)y(i.location+e,o/i.locationSize,u,r,c*d,(p+o/i.locationSize*e)*d,f)}else{if(s.isInstancedBufferAttribute){for(let e=0;e<i.locationSize;e++)_(i.location+e,s.meshPerAttribute);n.isInstancedMesh!==!0&&a._maxInstanceCount===void 0&&(a._maxInstanceCount=s.meshPerAttribute*s.count)}else for(let e=0;e<i.locationSize;e++)g(i.location+e);e.bindBuffer(e.ARRAY_BUFFER,l);for(let e=0;e<i.locationSize;e++)y(i.location+e,o/i.locationSize,u,r,o*d,o/i.locationSize*e*d,f)}}else if(c!==void 0){let t=c[r];if(t!==void 0)switch(t.length){case 2:e.vertexAttrib2fv(i.location,t);break;case 3:e.vertexAttrib3fv(i.location,t);break;case 4:e.vertexAttrib4fv(i.location,t);break;default:e.vertexAttrib1fv(i.location,t)}}}}v()}function x(){w();for(let e in r){let t=r[e];for(let e in t){let n=t[e];for(let e in n)u(n[e].object),delete n[e];delete t[e]}delete r[e]}}function S(e){if(r[e.id]===void 0)return;let t=r[e.id];for(let e in t){let n=t[e];for(let e in n)u(n[e].object),delete n[e];delete t[e]}delete r[e.id]}function C(e){for(let t in r){let n=r[t];if(n[e.id]===void 0)continue;let i=n[e.id];for(let e in i)u(i[e].object),delete i[e];delete n[e.id]}}function w(){T(),o=!0,a!==i&&(a=i,l(a.object))}function T(){i.geometry=null,i.program=null,i.wireframe=!1}return{setup:s,reset:w,resetDefaultState:T,dispose:x,releaseStatesOfGeometry:S,releaseStatesOfProgram:C,initAttributes:h,enableAttribute:g,disableUnusedAttributes:v}}function Di(e,t,n){let r;function i(e){r=e}function a(t,i){e.drawArrays(r,t,i),n.update(i,r,1)}function o(t,i,a){a!==0&&(e.drawArraysInstanced(r,t,i,a),n.update(i,r,a))}function s(e,i,a){if(a===0)return;t.get(`WEBGL_multi_draw`).multiDrawArraysWEBGL(r,e,0,i,0,a);let o=0;for(let e=0;e<a;e++)o+=i[e];n.update(o,r,1)}function c(e,i,a,s){if(a===0)return;let c=t.get(`WEBGL_multi_draw`);if(c===null)for(let t=0;t<e.length;t++)o(e[t],i[t],s[t]);else{c.multiDrawArraysInstancedWEBGL(r,e,0,i,0,s,0,a);let t=0;for(let e=0;e<a;e++)t+=i[e]*s[e];n.update(t,r,1)}}this.setMode=i,this.render=a,this.renderInstances=o,this.renderMultiDraw=s,this.renderMultiDrawInstances=c}function Oi(e,t,n,r){let i;function a(){if(i!==void 0)return i;if(t.has(`EXT_texture_filter_anisotropic`)===!0){let n=t.get(`EXT_texture_filter_anisotropic`);i=e.getParameter(n.MAX_TEXTURE_MAX_ANISOTROPY_EXT)}else i=0;return i}function o(t){return t===1023||r.convert(t)===e.getParameter(e.IMPLEMENTATION_COLOR_READ_FORMAT)}function s(n){let i=n===1016&&(t.has(`EXT_color_buffer_half_float`)||t.has(`EXT_color_buffer_float`));return!(n!==1009&&r.convert(n)!==e.getParameter(e.IMPLEMENTATION_COLOR_READ_TYPE)&&n!==1015&&!i)}function c(t){if(t===`highp`){if(e.getShaderPrecisionFormat(e.VERTEX_SHADER,e.HIGH_FLOAT).precision>0&&e.getShaderPrecisionFormat(e.FRAGMENT_SHADER,e.HIGH_FLOAT).precision>0)return`highp`;t=`mediump`}return t===`mediump`&&e.getShaderPrecisionFormat(e.VERTEX_SHADER,e.MEDIUM_FLOAT).precision>0&&e.getShaderPrecisionFormat(e.FRAGMENT_SHADER,e.MEDIUM_FLOAT).precision>0?`mediump`:`lowp`}let l=n.precision===void 0?`highp`:n.precision,u=c(l);u!==l&&(console.warn(`THREE.WebGLRenderer:`,l,`not supported, using`,u,`instead.`),l=u);let d=n.logarithmicDepthBuffer===!0,f=n.reverseDepthBuffer===!0&&t.has(`EXT_clip_control`),p=e.getParameter(e.MAX_TEXTURE_IMAGE_UNITS),m=e.getParameter(e.MAX_VERTEX_TEXTURE_IMAGE_UNITS),h=e.getParameter(e.MAX_TEXTURE_SIZE),g=e.getParameter(e.MAX_CUBE_MAP_TEXTURE_SIZE),_=e.getParameter(e.MAX_VERTEX_ATTRIBS),v=e.getParameter(e.MAX_VERTEX_UNIFORM_VECTORS),y=e.getParameter(e.MAX_VARYING_VECTORS),b=e.getParameter(e.MAX_FRAGMENT_UNIFORM_VECTORS),x=m>0,S=e.getParameter(e.MAX_SAMPLES);return{isWebGL2:!0,getMaxAnisotropy:a,getMaxPrecision:c,textureFormatReadable:o,textureTypeReadable:s,precision:l,logarithmicDepthBuffer:d,reverseDepthBuffer:f,maxTextures:p,maxVertexTextures:m,maxTextureSize:h,maxCubemapSize:g,maxAttributes:_,maxVertexUniforms:v,maxVaryings:y,maxFragmentUniforms:b,vertexTextures:x,maxSamples:S}}function ki(e){let t=this,n=null,r=0,i=!1,a=!1,o=new mi,s=new z,c={value:null,needsUpdate:!1};this.uniform=c,this.numPlanes=0,this.numIntersection=0,this.init=function(e,t){let n=e.length!==0||t||r!==0||i;return i=t,r=e.length,n},this.beginShadows=function(){a=!0,u(null)},this.endShadows=function(){a=!1},this.setGlobalState=function(e,t){n=u(e,t,0)},this.setState=function(t,o,s){let d=t.clippingPlanes,f=t.clipIntersection,p=t.clipShadows,m=e.get(t);if(!i||d===null||d.length===0||a&&!p)a?u(null):l();else{let e=a?0:r,t=e*4,i=m.clippingState||null;c.value=i,i=u(d,o,t,s);for(let e=0;e!==t;++e)i[e]=n[e];m.clippingState=i,this.numIntersection=f?this.numPlanes:0,this.numPlanes+=e}};function l(){c.value!==n&&(c.value=n,c.needsUpdate=r>0),t.numPlanes=r,t.numIntersection=0}function u(e,n,r,i){let a=e===null?0:e.length,l=null;if(a!==0){if(l=c.value,i!==!0||l===null){let t=r+a*4,i=n.matrixWorldInverse;s.getNormalMatrix(i),(l===null||l.length<t)&&(l=new Float32Array(t));for(let t=0,n=r;t!==a;++t,n+=4)o.copy(e[t]).applyMatrix4(i,s),o.normal.toArray(l,n),l[n+3]=o.constant}c.value=l,c.needsUpdate=!0}return t.numPlanes=a,t.numIntersection=0,l}}function Ai(e){let t=new WeakMap;function n(e,t){return t===303?e.mapping=301:t===304&&(e.mapping=302),e}function r(r){if(r&&r.isTexture){let a=r.mapping;if(a===303||a===304){if(t.has(r)){let e=t.get(r).texture;return n(e,r.mapping)}{let a=r.image;if(a&&a.height>0){let o=new ui(a.height);return o.fromEquirectangularTexture(e,r),t.set(r,o),r.addEventListener(`dispose`,i),n(o.texture,r.mapping)}return null}}}return r}function i(e){let n=e.target;n.removeEventListener(`dispose`,i);let r=t.get(n);r!==void 0&&(t.delete(n),r.dispose())}function a(){t=new WeakMap}return{get:r,dispose:a}}var ji=class extends ti{constructor(e=-1,t=1,n=1,r=-1,i=.1,a=2e3){super(),this.isOrthographicCamera=!0,this.type=`OrthographicCamera`,this.zoom=1,this.view=null,this.left=e,this.right=t,this.top=n,this.bottom=r,this.near=i,this.far=a,this.updateProjectionMatrix()}copy(e,t){return super.copy(e,t),this.left=e.left,this.right=e.right,this.top=e.top,this.bottom=e.bottom,this.near=e.near,this.far=e.far,this.zoom=e.zoom,this.view=e.view===null?null:Object.assign({},e.view),this}setViewOffset(e,t,n,r,i,a){this.view===null&&(this.view={enabled:!0,fullWidth:1,fullHeight:1,offsetX:0,offsetY:0,width:1,height:1}),this.view.enabled=!0,this.view.fullWidth=e,this.view.fullHeight=t,this.view.offsetX=n,this.view.offsetY=r,this.view.width=i,this.view.height=a,this.updateProjectionMatrix()}clearViewOffset(){this.view!==null&&(this.view.enabled=!1),this.updateProjectionMatrix()}updateProjectionMatrix(){let e=(this.right-this.left)/(2*this.zoom),t=(this.top-this.bottom)/(2*this.zoom),n=(this.right+this.left)/2,r=(this.top+this.bottom)/2,i=n-e,a=n+e,o=r+t,s=r-t;if(this.view!==null&&this.view.enabled){let e=(this.right-this.left)/this.view.fullWidth/this.zoom,t=(this.top-this.bottom)/this.view.fullHeight/this.zoom;i+=e*this.view.offsetX,a=i+e*this.view.width,o-=t*this.view.offsetY,s=o-t*this.view.height}this.projectionMatrix.makeOrthographic(i,a,o,s,this.near,this.far,this.coordinateSystem),this.projectionMatrixInverse.copy(this.projectionMatrix).invert()}toJSON(e){let t=super.toJSON(e);return t.object.zoom=this.zoom,t.object.left=this.left,t.object.right=this.right,t.object.top=this.top,t.object.bottom=this.bottom,t.object.near=this.near,t.object.far=this.far,this.view!==null&&(t.object.view=Object.assign({},this.view)),t}},Mi=4,Ni=[.125,.215,.35,.446,.526,.582],Pi=20,Fi=new ji,Ii=new W,Li=null,Ri=0,zi=0,Bi=!1,Vi=(1+Math.sqrt(5))/2,Hi=1/Vi,Ui=[new H(-Vi,Hi,0),new H(Vi,Hi,0),new H(-Hi,0,Vi),new H(Hi,0,Vi),new H(0,Vi,-Hi),new H(0,Vi,Hi),new H(-1,1,-1),new H(1,1,-1),new H(-1,1,1),new H(1,1,1)],Wi=class{constructor(e){this._renderer=e,this._pingPongRenderTarget=null,this._lodMax=0,this._cubeSize=0,this._lodPlanes=[],this._sizeLods=[],this._sigmas=[],this._blurMaterial=null,this._cubemapMaterial=null,this._equirectMaterial=null,this._compileMaterial(this._blurMaterial)}fromScene(e,t=0,n=.1,r=100){Li=this._renderer.getRenderTarget(),Ri=this._renderer.getActiveCubeFace(),zi=this._renderer.getActiveMipmapLevel(),Bi=this._renderer.xr.enabled,this._renderer.xr.enabled=!1,this._setSize(256);let i=this._allocateTargets();return i.depthBuffer=!0,this._sceneToCubeUV(e,n,r,i),t>0&&this._blur(i,0,0,t),this._applyPMREM(i),this._cleanup(i),i}fromEquirectangular(e,t=null){return this._fromTexture(e,t)}fromCubemap(e,t=null){return this._fromTexture(e,t)}compileCubemapShader(){this._cubemapMaterial===null&&(this._cubemapMaterial=Xi(),this._compileMaterial(this._cubemapMaterial))}compileEquirectangularShader(){this._equirectMaterial===null&&(this._equirectMaterial=Yi(),this._compileMaterial(this._equirectMaterial))}dispose(){this._dispose(),this._cubemapMaterial!==null&&this._cubemapMaterial.dispose(),this._equirectMaterial!==null&&this._equirectMaterial.dispose()}_setSize(e){this._lodMax=Math.floor(Math.log2(e)),this._cubeSize=2**this._lodMax}_dispose(){this._blurMaterial!==null&&this._blurMaterial.dispose(),this._pingPongRenderTarget!==null&&this._pingPongRenderTarget.dispose();for(let e=0;e<this._lodPlanes.length;e++)this._lodPlanes[e].dispose()}_cleanup(e){this._renderer.setRenderTarget(Li,Ri,zi),this._renderer.xr.enabled=Bi,e.scissorTest=!1,qi(e,0,0,e.width,e.height)}_fromTexture(e,t){e.mapping===301||e.mapping===302?this._setSize(e.image.length===0?16:e.image[0].width||e.image[0].image.width):this._setSize(e.image.width/4),Li=this._renderer.getRenderTarget(),Ri=this._renderer.getActiveCubeFace(),zi=this._renderer.getActiveMipmapLevel(),Bi=this._renderer.xr.enabled,this._renderer.xr.enabled=!1;let n=t||this._allocateTargets();return this._textureToCubeUV(e,n),this._applyPMREM(n),this._cleanup(n),n}_allocateTargets(){let e=3*Math.max(this._cubeSize,112),t=4*this._cubeSize,n={magFilter:l,minFilter:l,generateMipmaps:!1,type:y,format:E,colorSpace:ze,depthBuffer:!1},r=Ki(e,t,n);if(this._pingPongRenderTarget===null||this._pingPongRenderTarget.width!==e||this._pingPongRenderTarget.height!==t){this._pingPongRenderTarget!==null&&this._dispose(),this._pingPongRenderTarget=Ki(e,t,n);let{_lodMax:r}=this;({sizeLods:this._sizeLods,lodPlanes:this._lodPlanes,sigmas:this._sigmas}=Gi(r)),this._blurMaterial=Ji(r,e,t)}return r}_compileMaterial(e){let t=new Ur(this._lodPlanes[0],e);this._renderer.compile(t,Fi)}_sceneToCubeUV(e,t,n,r){let i=new ai(90,1,t,n),a=[1,-1,1,1,1,1],o=[1,1,1,-1,-1,-1],s=this._renderer,c=s.autoClear,l=s.toneMapping;s.getClearColor(Ii),s.toneMapping=0,s.autoClear=!1;let u=new _r({name:`PMREM.Background`,side:1,depthWrite:!1,depthTest:!1}),d=new Ur(new Kr,u),f=!1,p=e.background;p?p.isColor&&(u.color.copy(p),e.background=null,f=!0):(u.color.copy(Ii),f=!0);for(let t=0;t<6;t++){let n=t%3;n===0?(i.up.set(0,a[t],0),i.lookAt(o[t],0,0)):n===1?(i.up.set(0,0,a[t]),i.lookAt(0,o[t],0)):(i.up.set(0,a[t],0),i.lookAt(0,0,o[t]));let c=this._cubeSize;qi(r,n*c,t>2?c:0,c,c),s.setRenderTarget(r),f&&s.render(d,i),s.render(e,i)}d.geometry.dispose(),d.material.dispose(),s.toneMapping=l,s.autoClear=c,e.background=p}_textureToCubeUV(e,t){let n=this._renderer,r=e.mapping===301||e.mapping===302;r?(this._cubemapMaterial===null&&(this._cubemapMaterial=Xi()),this._cubemapMaterial.uniforms.flipEnvMap.value=e.isRenderTargetTexture===!1?-1:1):this._equirectMaterial===null&&(this._equirectMaterial=Yi());let i=r?this._cubemapMaterial:this._equirectMaterial,a=new Ur(this._lodPlanes[0],i),o=i.uniforms;o.envMap.value=e;let s=this._cubeSize;qi(t,0,0,3*s,2*s),n.setRenderTarget(t),n.render(a,Fi)}_applyPMREM(e){let t=this._renderer,n=t.autoClear;t.autoClear=!1;let r=this._lodPlanes.length;for(let t=1;t<r;t++){let n=Math.sqrt(this._sigmas[t]*this._sigmas[t]-this._sigmas[t-1]*this._sigmas[t-1]),i=Ui[(r-t-1)%Ui.length];this._blur(e,t-1,t,n,i)}t.autoClear=n}_blur(e,t,n,r,i){let a=this._pingPongRenderTarget;this._halfBlur(e,a,t,n,r,`latitudinal`,i),this._halfBlur(a,e,n,n,r,`longitudinal`,i)}_halfBlur(e,t,n,r,i,a,o){let s=this._renderer,c=this._blurMaterial;a!==`latitudinal`&&a!==`longitudinal`&&console.error(`blur direction must be either latitudinal or longitudinal!`);let l=new Ur(this._lodPlanes[r],c),u=c.uniforms,d=this._sizeLods[n]-1,f=isFinite(i)?Math.PI/(2*d):2*Math.PI/39,p=i/f,m=isFinite(i)?1+Math.floor(3*p):Pi;m>Pi&&console.warn(`sigmaRadians, ${i}, is too large and will clip, as it requested ${m} samples when the maximum is set to ${Pi}`);let h=[],g=0;for(let e=0;e<Pi;++e){let t=e/p,n=Math.exp(-t*t/2);h.push(n),e===0?g+=n:e<m&&(g+=2*n)}for(let e=0;e<h.length;e++)h[e]=h[e]/g;u.envMap.value=e.texture,u.samples.value=m,u.weights.value=h,u.latitudinal.value=a===`latitudinal`,o&&(u.poleAxis.value=o);let{_lodMax:_}=this;u.dTheta.value=f,u.mipInt.value=_-n;let v=this._sizeLods[r];qi(t,3*v*(r>_-Mi?r-_+Mi:0),4*(this._cubeSize-v),3*v,2*v),s.setRenderTarget(t),s.render(l,Fi)}};function Gi(e){let t=[],n=[],r=[],i=e,a=e-Mi+1+Ni.length;for(let o=0;o<a;o++){let a=2**i;n.push(a);let s=1/a;o>e-Mi?s=Ni[o-e+Mi-1]:o===0&&(s=0),r.push(s);let c=1/(a-2),l=-c,u=1+c,d=[l,l,u,l,u,u,l,l,u,u,l,u],f=new Float32Array(108),p=new Float32Array(72),m=new Float32Array(36);for(let e=0;e<6;e++){let t=e%3*2/3-1,n=e>2?0:-1,r=[t,n,0,t+2/3,n,0,t+2/3,n+1,0,t,n,0,t+2/3,n+1,0,t,n+1,0];f.set(r,18*e),p.set(d,12*e);let i=[e,e,e,e,e,e];m.set(i,6*e)}let h=new jr;h.setAttribute(`position`,new br(f,3)),h.setAttribute(`uv`,new br(p,2)),h.setAttribute(`faceIndex`,new br(m,1)),t.push(h),i>Mi&&i--}return{lodPlanes:t,sizeLods:n,sigmas:r}}function Ki(e,t,n){let r=new Wt(e,t,n);return r.texture.mapping=306,r.texture.name=`PMREM.cubeUv`,r.scissorTest=!0,r}function qi(e,t,n,r,i){e.viewport.set(t,n,r,i),e.scissor.set(t,n,r,i)}function Ji(e,t,n){let r=new Float32Array(Pi),i=new H(0,1,0);return new ei({name:`SphericalGaussianBlur`,defines:{n:Pi,CUBEUV_TEXEL_WIDTH:1/t,CUBEUV_TEXEL_HEIGHT:1/n,CUBEUV_MAX_MIP:`${e}.0`},uniforms:{envMap:{value:null},samples:{value:1},weights:{value:r},latitudinal:{value:!1},dTheta:{value:0},mipInt:{value:0},poleAxis:{value:i}},vertexShader:Zi(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;
			uniform int samples;
			uniform float weights[ n ];
			uniform bool latitudinal;
			uniform float dTheta;
			uniform float mipInt;
			uniform vec3 poleAxis;

			#define ENVMAP_TYPE_CUBE_UV
			#include <cube_uv_reflection_fragment>

			vec3 getSample( float theta, vec3 axis ) {

				float cosTheta = cos( theta );
				// Rodrigues' axis-angle rotation
				vec3 sampleDirection = vOutputDirection * cosTheta
					+ cross( axis, vOutputDirection ) * sin( theta )
					+ axis * dot( axis, vOutputDirection ) * ( 1.0 - cosTheta );

				return bilinearCubeUV( envMap, sampleDirection, mipInt );

			}

			void main() {

				vec3 axis = latitudinal ? poleAxis : cross( poleAxis, vOutputDirection );

				if ( all( equal( axis, vec3( 0.0 ) ) ) ) {

					axis = vec3( vOutputDirection.z, 0.0, - vOutputDirection.x );

				}

				axis = normalize( axis );

				gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );
				gl_FragColor.rgb += weights[ 0 ] * getSample( 0.0, axis );

				for ( int i = 1; i < n; i++ ) {

					if ( i >= samples ) {

						break;

					}

					float theta = dTheta * float( i );
					gl_FragColor.rgb += weights[ i ] * getSample( -1.0 * theta, axis );
					gl_FragColor.rgb += weights[ i ] * getSample( theta, axis );

				}

			}
		`,blending:0,depthTest:!1,depthWrite:!1})}function Yi(){return new ei({name:`EquirectangularToCubeUV`,uniforms:{envMap:{value:null}},vertexShader:Zi(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;

			#include <common>

			void main() {

				vec3 outputDirection = normalize( vOutputDirection );
				vec2 uv = equirectUv( outputDirection );

				gl_FragColor = vec4( texture2D ( envMap, uv ).rgb, 1.0 );

			}
		`,blending:0,depthTest:!1,depthWrite:!1})}function Xi(){return new ei({name:`CubemapToCubeUV`,uniforms:{envMap:{value:null},flipEnvMap:{value:-1}},vertexShader:Zi(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			uniform float flipEnvMap;

			varying vec3 vOutputDirection;

			uniform samplerCube envMap;

			void main() {

				gl_FragColor = textureCube( envMap, vec3( flipEnvMap * vOutputDirection.x, vOutputDirection.yz ) );

			}
		`,blending:0,depthTest:!1,depthWrite:!1})}function Zi(){return`

		precision mediump float;
		precision mediump int;

		attribute float faceIndex;

		varying vec3 vOutputDirection;

		// RH coordinate system; PMREM face-indexing convention
		vec3 getDirection( vec2 uv, float face ) {

			uv = 2.0 * uv - 1.0;

			vec3 direction = vec3( uv, 1.0 );

			if ( face == 0.0 ) {

				direction = direction.zyx; // ( 1, v, u ) pos x

			} else if ( face == 1.0 ) {

				direction = direction.xzy;
				direction.xz *= -1.0; // ( -u, 1, -v ) pos y

			} else if ( face == 2.0 ) {

				direction.x *= -1.0; // ( -u, v, 1 ) pos z

			} else if ( face == 3.0 ) {

				direction = direction.zyx;
				direction.xz *= -1.0; // ( -1, v, -u ) neg x

			} else if ( face == 4.0 ) {

				direction = direction.xzy;
				direction.xy *= -1.0; // ( -u, -1, v ) neg y

			} else if ( face == 5.0 ) {

				direction.z *= -1.0; // ( u, v, -1 ) neg z

			}

			return direction;

		}

		void main() {

			vOutputDirection = getDirection( uv, faceIndex );
			gl_Position = vec4( position, 1.0 );

		}
	`}function Qi(e){let t=new WeakMap,n=null;function r(r){if(r&&r.isTexture){let o=r.mapping,s=o===303||o===304,c=o===301||o===302;if(s||c){let o=t.get(r),l=o===void 0?0:o.texture.pmremVersion;if(r.isRenderTargetTexture&&r.pmremVersion!==l)return n===null&&(n=new Wi(e)),o=s?n.fromEquirectangular(r,o):n.fromCubemap(r,o),o.texture.pmremVersion=r.pmremVersion,t.set(r,o),o.texture;if(o!==void 0)return o.texture;{let l=r.image;return s&&l&&l.height>0||c&&l&&i(l)?(n===null&&(n=new Wi(e)),o=s?n.fromEquirectangular(r):n.fromCubemap(r),o.texture.pmremVersion=r.pmremVersion,t.set(r,o),r.addEventListener(`dispose`,a),o.texture):null}}}return r}function i(e){let t=0;for(let n=0;n<6;n++)e[n]!==void 0&&t++;return t===6}function a(e){let n=e.target;n.removeEventListener(`dispose`,a);let r=t.get(n);r!==void 0&&(t.delete(n),r.dispose())}function o(){t=new WeakMap,n!==null&&(n.dispose(),n=null)}return{get:r,dispose:o}}function $i(e){let t={};function n(n){if(t[n]!==void 0)return t[n];let r;switch(n){case`WEBGL_depth_texture`:r=e.getExtension(`WEBGL_depth_texture`)||e.getExtension(`MOZ_WEBGL_depth_texture`)||e.getExtension(`WEBKIT_WEBGL_depth_texture`);break;case`EXT_texture_filter_anisotropic`:r=e.getExtension(`EXT_texture_filter_anisotropic`)||e.getExtension(`MOZ_EXT_texture_filter_anisotropic`)||e.getExtension(`WEBKIT_EXT_texture_filter_anisotropic`);break;case`WEBGL_compressed_texture_s3tc`:r=e.getExtension(`WEBGL_compressed_texture_s3tc`)||e.getExtension(`MOZ_WEBGL_compressed_texture_s3tc`)||e.getExtension(`WEBKIT_WEBGL_compressed_texture_s3tc`);break;case`WEBGL_compressed_texture_pvrtc`:r=e.getExtension(`WEBGL_compressed_texture_pvrtc`)||e.getExtension(`WEBKIT_WEBGL_compressed_texture_pvrtc`);break;default:r=e.getExtension(n)}return t[n]=r,r}return{has:function(e){return n(e)!==null},init:function(){n(`EXT_color_buffer_float`),n(`WEBGL_clip_cull_distance`),n(`OES_texture_float_linear`),n(`EXT_color_buffer_half_float`),n(`WEBGL_multisampled_render_to_texture`),n(`WEBGL_render_shared_exponent`)},get:function(e){let t=n(e);return t===null&&wt(`THREE.WebGLRenderer: `+e+` extension not supported.`),t}}}function ea(e,t,n,r){let i={},a=new WeakMap;function o(e){let s=e.target;s.index!==null&&t.remove(s.index);for(let e in s.attributes)t.remove(s.attributes[e]);for(let e in s.morphAttributes){let n=s.morphAttributes[e];for(let e=0,r=n.length;e<r;e++)t.remove(n[e])}s.removeEventListener(`dispose`,o),delete i[s.id];let c=a.get(s);c&&(t.remove(c),a.delete(s)),r.releaseStatesOfGeometry(s),s.isInstancedBufferGeometry===!0&&delete s._maxInstanceCount,n.memory.geometries--}function s(e,t){return i[t.id]===!0?t:(t.addEventListener(`dispose`,o),i[t.id]=!0,n.memory.geometries++,t)}function c(n){let r=n.attributes;for(let n in r)t.update(r[n],e.ARRAY_BUFFER);let i=n.morphAttributes;for(let n in i){let r=i[n];for(let n=0,i=r.length;n<i;n++)t.update(r[n],e.ARRAY_BUFFER)}}function l(e){let n=[],r=e.index,i=e.attributes.position,o=0;if(r!==null){let e=r.array;o=r.version;for(let t=0,r=e.length;t<r;t+=3){let r=e[t+0],i=e[t+1],a=e[t+2];n.push(r,i,i,a,a,r)}}else if(i!==void 0){let e=i.array;o=i.version;for(let t=0,r=e.length/3-1;t<r;t+=3){let e=t+0,r=t+1,i=t+2;n.push(e,r,r,i,i,e)}}else return;let s=new(bt(n)?Sr:xr)(n,1);s.version=o;let c=a.get(e);c&&t.remove(c),a.set(e,s)}function u(e){let t=a.get(e);if(t){let n=e.index;n!==null&&t.version<n.version&&l(e)}else l(e);return a.get(e)}return{get:s,update:c,getWireframeAttribute:u}}function ta(e,t,n){let r;function i(e){r=e}let a,o;function s(e){a=e.type,o=e.bytesPerElement}function c(t,i){e.drawElements(r,i,a,t*o),n.update(i,r,1)}function l(t,i,s){s!==0&&(e.drawElementsInstanced(r,i,a,t*o,s),n.update(i,r,s))}function u(e,i,o){if(o===0)return;t.get(`WEBGL_multi_draw`).multiDrawElementsWEBGL(r,i,0,a,e,0,o);let s=0;for(let e=0;e<o;e++)s+=i[e];n.update(s,r,1)}function d(e,i,s,c){if(s===0)return;let u=t.get(`WEBGL_multi_draw`);if(u===null)for(let t=0;t<e.length;t++)l(e[t]/o,i[t],c[t]);else{u.multiDrawElementsInstancedWEBGL(r,i,0,a,e,0,c,0,s);let t=0;for(let e=0;e<s;e++)t+=i[e]*c[e];n.update(t,r,1)}}this.setMode=i,this.setIndex=s,this.render=c,this.renderInstances=l,this.renderMultiDraw=u,this.renderMultiDrawInstances=d}function na(e){let t={geometries:0,textures:0},n={frame:0,calls:0,triangles:0,points:0,lines:0};function r(t,r,i){switch(n.calls++,r){case e.TRIANGLES:n.triangles+=t/3*i;break;case e.LINES:n.lines+=t/2*i;break;case e.LINE_STRIP:n.lines+=i*(t-1);break;case e.LINE_LOOP:n.lines+=i*t;break;case e.POINTS:n.points+=i*t;break;default:console.error(`THREE.WebGLInfo: Unknown draw mode:`,r)}}function i(){n.calls=0,n.triangles=0,n.points=0,n.lines=0}return{memory:t,render:n,programs:null,autoReset:!0,reset:i,update:r}}function ra(e,t,n){let r=new WeakMap,i=new B;function a(a,o,s){let c=a.morphTargetInfluences,l=o.morphAttributes.position||o.morphAttributes.normal||o.morphAttributes.color,u=l===void 0?0:l.length,d=r.get(o);if(d===void 0||d.count!==u){d!==void 0&&d.texture.dispose();let e=o.morphAttributes.position!==void 0,n=o.morphAttributes.normal!==void 0,a=o.morphAttributes.color!==void 0,s=o.morphAttributes.position||[],c=o.morphAttributes.normal||[],l=o.morphAttributes.color||[],p=0;e===!0&&(p=1),n===!0&&(p=2),a===!0&&(p=3);let m=o.attributes.position.count*p,h=1;m>t.maxTextureSize&&(h=Math.ceil(m/t.maxTextureSize),m=t.maxTextureSize);let g=new Float32Array(m*h*4*u),_=new Gt(g,m,h,u);_.type=v,_.needsUpdate=!0;let y=p*4;for(let t=0;t<u;t++){let r=s[t],o=c[t],u=l[t],d=m*h*4*t;for(let t=0;t<r.count;t++){let s=t*y;e===!0&&(i.fromBufferAttribute(r,t),g[d+s+0]=i.x,g[d+s+1]=i.y,g[d+s+2]=i.z,g[d+s+3]=0),n===!0&&(i.fromBufferAttribute(o,t),g[d+s+4]=i.x,g[d+s+5]=i.y,g[d+s+6]=i.z,g[d+s+7]=0),a===!0&&(i.fromBufferAttribute(u,t),g[d+s+8]=i.x,g[d+s+9]=i.y,g[d+s+10]=i.z,g[d+s+11]=u.itemSize===4?i.w:1)}}d={count:u,texture:_,size:new R(m,h)},r.set(o,d);function f(){_.dispose(),r.delete(o),o.removeEventListener(`dispose`,f)}o.addEventListener(`dispose`,f)}if(a.isInstancedMesh===!0&&a.morphTexture!==null)s.getUniforms().setValue(e,`morphTexture`,a.morphTexture,n);else{let t=0;for(let e=0;e<c.length;e++)t+=c[e];let n=o.morphTargetsRelative?1:1-t;s.getUniforms().setValue(e,`morphTargetBaseInfluence`,n),s.getUniforms().setValue(e,`morphTargetInfluences`,c)}s.getUniforms().setValue(e,`morphTargetsTexture`,d.texture,n),s.getUniforms().setValue(e,`morphTargetsTextureSize`,d.size)}return{update:a}}function ia(e,t,n,r){let i=new WeakMap;function a(a){let o=r.render.frame,c=a.geometry,l=t.get(a,c);if(i.get(l)!==o&&(t.update(l),i.set(l,o)),a.isInstancedMesh&&(a.hasEventListener(`dispose`,s)===!1&&a.addEventListener(`dispose`,s),i.get(a)!==o&&(n.update(a.instanceMatrix,e.ARRAY_BUFFER),a.instanceColor!==null&&n.update(a.instanceColor,e.ARRAY_BUFFER),i.set(a,o))),a.isSkinnedMesh){let e=a.skeleton;i.get(e)!==o&&(e.update(),i.set(e,o))}return l}function o(){i=new WeakMap}function s(e){let t=e.target;t.removeEventListener(`dispose`,s),n.remove(t.instanceMatrix),t.instanceColor!==null&&n.remove(t.instanceColor)}return{update:a,dispose:o}}var aa=class extends Ht{constructor(e,t,n,r,i,a,s,c,l,u=k){if(u!==1026&&u!==1027)throw Error(`DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat`);n===void 0&&u===1026&&(n=_),n===void 0&&u===1027&&(n=S),super(null,r,i,a,s,c,u,n,l),this.isDepthTexture=!0,this.image={width:e,height:t},this.magFilter=s===void 0?o:s,this.minFilter=c===void 0?o:c,this.flipY=!1,this.generateMipmaps=!1,this.compareFunction=null}copy(e){return super.copy(e),this.compareFunction=e.compareFunction,this}toJSON(e){let t=super.toJSON(e);return this.compareFunction!==null&&(t.compareFunction=this.compareFunction),t}},oa=new Ht,sa=new aa(1,1),ca=new Gt,la=new Kt,ua=new li,da=[],fa=[],pa=new Float32Array(16),ma=new Float32Array(9),ha=new Float32Array(4);function ga(e,t,n){let r=e[0];if(r<=0||r>0)return e;let i=t*n,a=da[i];if(a===void 0&&(a=new Float32Array(i),da[i]=a),t!==0){r.toArray(a,0);for(let r=1,i=0;r!==t;++r)i+=n,e[r].toArray(a,i)}return a}function _a(e,t){if(e.length!==t.length)return!1;for(let n=0,r=e.length;n<r;n++)if(e[n]!==t[n])return!1;return!0}function va(e,t){for(let n=0,r=t.length;n<r;n++)e[n]=t[n]}function ya(e,t){let n=fa[t];n===void 0&&(n=new Int32Array(t),fa[t]=n);for(let r=0;r!==t;++r)n[r]=e.allocateTextureUnit();return n}function ba(e,t){let n=this.cache;n[0]!==t&&(e.uniform1f(this.addr,t),n[0]=t)}function xa(e,t){let n=this.cache;if(t.x!==void 0)(n[0]!==t.x||n[1]!==t.y)&&(e.uniform2f(this.addr,t.x,t.y),n[0]=t.x,n[1]=t.y);else{if(_a(n,t))return;e.uniform2fv(this.addr,t),va(n,t)}}function Sa(e,t){let n=this.cache;if(t.x!==void 0)(n[0]!==t.x||n[1]!==t.y||n[2]!==t.z)&&(e.uniform3f(this.addr,t.x,t.y,t.z),n[0]=t.x,n[1]=t.y,n[2]=t.z);else if(t.r!==void 0)(n[0]!==t.r||n[1]!==t.g||n[2]!==t.b)&&(e.uniform3f(this.addr,t.r,t.g,t.b),n[0]=t.r,n[1]=t.g,n[2]=t.b);else{if(_a(n,t))return;e.uniform3fv(this.addr,t),va(n,t)}}function Ca(e,t){let n=this.cache;if(t.x!==void 0)(n[0]!==t.x||n[1]!==t.y||n[2]!==t.z||n[3]!==t.w)&&(e.uniform4f(this.addr,t.x,t.y,t.z,t.w),n[0]=t.x,n[1]=t.y,n[2]=t.z,n[3]=t.w);else{if(_a(n,t))return;e.uniform4fv(this.addr,t),va(n,t)}}function wa(e,t){let n=this.cache,r=t.elements;if(r===void 0){if(_a(n,t))return;e.uniformMatrix2fv(this.addr,!1,t),va(n,t)}else{if(_a(n,r))return;ha.set(r),e.uniformMatrix2fv(this.addr,!1,ha),va(n,r)}}function Ta(e,t){let n=this.cache,r=t.elements;if(r===void 0){if(_a(n,t))return;e.uniformMatrix3fv(this.addr,!1,t),va(n,t)}else{if(_a(n,r))return;ma.set(r),e.uniformMatrix3fv(this.addr,!1,ma),va(n,r)}}function Ea(e,t){let n=this.cache,r=t.elements;if(r===void 0){if(_a(n,t))return;e.uniformMatrix4fv(this.addr,!1,t),va(n,t)}else{if(_a(n,r))return;pa.set(r),e.uniformMatrix4fv(this.addr,!1,pa),va(n,r)}}function Da(e,t){let n=this.cache;n[0]!==t&&(e.uniform1i(this.addr,t),n[0]=t)}function Oa(e,t){let n=this.cache;if(t.x!==void 0)(n[0]!==t.x||n[1]!==t.y)&&(e.uniform2i(this.addr,t.x,t.y),n[0]=t.x,n[1]=t.y);else{if(_a(n,t))return;e.uniform2iv(this.addr,t),va(n,t)}}function ka(e,t){let n=this.cache;if(t.x!==void 0)(n[0]!==t.x||n[1]!==t.y||n[2]!==t.z)&&(e.uniform3i(this.addr,t.x,t.y,t.z),n[0]=t.x,n[1]=t.y,n[2]=t.z);else{if(_a(n,t))return;e.uniform3iv(this.addr,t),va(n,t)}}function Aa(e,t){let n=this.cache;if(t.x!==void 0)(n[0]!==t.x||n[1]!==t.y||n[2]!==t.z||n[3]!==t.w)&&(e.uniform4i(this.addr,t.x,t.y,t.z,t.w),n[0]=t.x,n[1]=t.y,n[2]=t.z,n[3]=t.w);else{if(_a(n,t))return;e.uniform4iv(this.addr,t),va(n,t)}}function ja(e,t){let n=this.cache;n[0]!==t&&(e.uniform1ui(this.addr,t),n[0]=t)}function Ma(e,t){let n=this.cache;if(t.x!==void 0)(n[0]!==t.x||n[1]!==t.y)&&(e.uniform2ui(this.addr,t.x,t.y),n[0]=t.x,n[1]=t.y);else{if(_a(n,t))return;e.uniform2uiv(this.addr,t),va(n,t)}}function Na(e,t){let n=this.cache;if(t.x!==void 0)(n[0]!==t.x||n[1]!==t.y||n[2]!==t.z)&&(e.uniform3ui(this.addr,t.x,t.y,t.z),n[0]=t.x,n[1]=t.y,n[2]=t.z);else{if(_a(n,t))return;e.uniform3uiv(this.addr,t),va(n,t)}}function Pa(e,t){let n=this.cache;if(t.x!==void 0)(n[0]!==t.x||n[1]!==t.y||n[2]!==t.z||n[3]!==t.w)&&(e.uniform4ui(this.addr,t.x,t.y,t.z,t.w),n[0]=t.x,n[1]=t.y,n[2]=t.z,n[3]=t.w);else{if(_a(n,t))return;e.uniform4uiv(this.addr,t),va(n,t)}}function Fa(e,t,n){let r=this.cache,i=n.allocateTextureUnit();r[0]!==i&&(e.uniform1i(this.addr,i),r[0]=i);let a;this.type===e.SAMPLER_2D_SHADOW?(sa.compareFunction=515,a=sa):a=oa,n.setTexture2D(t||a,i)}function Ia(e,t,n){let r=this.cache,i=n.allocateTextureUnit();r[0]!==i&&(e.uniform1i(this.addr,i),r[0]=i),n.setTexture3D(t||la,i)}function La(e,t,n){let r=this.cache,i=n.allocateTextureUnit();r[0]!==i&&(e.uniform1i(this.addr,i),r[0]=i),n.setTextureCube(t||ua,i)}function Ra(e,t,n){let r=this.cache,i=n.allocateTextureUnit();r[0]!==i&&(e.uniform1i(this.addr,i),r[0]=i),n.setTexture2DArray(t||ca,i)}function za(e){switch(e){case 5126:return ba;case 35664:return xa;case 35665:return Sa;case 35666:return Ca;case 35674:return wa;case 35675:return Ta;case 35676:return Ea;case 5124:case 35670:return Da;case 35667:case 35671:return Oa;case 35668:case 35672:return ka;case 35669:case 35673:return Aa;case 5125:return ja;case 36294:return Ma;case 36295:return Na;case 36296:return Pa;case 35678:case 36198:case 36298:case 36306:case 35682:return Fa;case 35679:case 36299:case 36307:return Ia;case 35680:case 36300:case 36308:case 36293:return La;case 36289:case 36303:case 36311:case 36292:return Ra}}function Ba(e,t){e.uniform1fv(this.addr,t)}function Va(e,t){let n=ga(t,this.size,2);e.uniform2fv(this.addr,n)}function Ha(e,t){let n=ga(t,this.size,3);e.uniform3fv(this.addr,n)}function Ua(e,t){let n=ga(t,this.size,4);e.uniform4fv(this.addr,n)}function Wa(e,t){let n=ga(t,this.size,4);e.uniformMatrix2fv(this.addr,!1,n)}function Ga(e,t){let n=ga(t,this.size,9);e.uniformMatrix3fv(this.addr,!1,n)}function Ka(e,t){let n=ga(t,this.size,16);e.uniformMatrix4fv(this.addr,!1,n)}function qa(e,t){e.uniform1iv(this.addr,t)}function Ja(e,t){e.uniform2iv(this.addr,t)}function Ya(e,t){e.uniform3iv(this.addr,t)}function Xa(e,t){e.uniform4iv(this.addr,t)}function Za(e,t){e.uniform1uiv(this.addr,t)}function Qa(e,t){e.uniform2uiv(this.addr,t)}function $a(e,t){e.uniform3uiv(this.addr,t)}function eo(e,t){e.uniform4uiv(this.addr,t)}function to(e,t,n){let r=this.cache,i=t.length,a=ya(n,i);_a(r,a)||(e.uniform1iv(this.addr,a),va(r,a));for(let e=0;e!==i;++e)n.setTexture2D(t[e]||oa,a[e])}function no(e,t,n){let r=this.cache,i=t.length,a=ya(n,i);_a(r,a)||(e.uniform1iv(this.addr,a),va(r,a));for(let e=0;e!==i;++e)n.setTexture3D(t[e]||la,a[e])}function ro(e,t,n){let r=this.cache,i=t.length,a=ya(n,i);_a(r,a)||(e.uniform1iv(this.addr,a),va(r,a));for(let e=0;e!==i;++e)n.setTextureCube(t[e]||ua,a[e])}function io(e,t,n){let r=this.cache,i=t.length,a=ya(n,i);_a(r,a)||(e.uniform1iv(this.addr,a),va(r,a));for(let e=0;e!==i;++e)n.setTexture2DArray(t[e]||ca,a[e])}function ao(e){switch(e){case 5126:return Ba;case 35664:return Va;case 35665:return Ha;case 35666:return Ua;case 35674:return Wa;case 35675:return Ga;case 35676:return Ka;case 5124:case 35670:return qa;case 35667:case 35671:return Ja;case 35668:case 35672:return Ya;case 35669:case 35673:return Xa;case 5125:return Za;case 36294:return Qa;case 36295:return $a;case 36296:return eo;case 35678:case 36198:case 36298:case 36306:case 35682:return to;case 35679:case 36299:case 36307:return no;case 35680:case 36300:case 36308:case 36293:return ro;case 36289:case 36303:case 36311:case 36292:return io}}var oo=class{constructor(e,t,n){this.id=e,this.addr=n,this.cache=[],this.type=t.type,this.setValue=za(t.type)}},so=class{constructor(e,t,n){this.id=e,this.addr=n,this.cache=[],this.type=t.type,this.size=t.size,this.setValue=ao(t.type)}},co=class{constructor(e){this.id=e,this.seq=[],this.map={}}setValue(e,t,n){let r=this.seq;for(let i=0,a=r.length;i!==a;++i){let a=r[i];a.setValue(e,t[a.id],n)}}},lo=/(\w+)(\])?(\[|\.)?/g;function uo(e,t){e.seq.push(t),e.map[t.id]=t}function fo(e,t,n){let r=e.name,i=r.length;for(lo.lastIndex=0;;){let a=lo.exec(r),o=lo.lastIndex,s=a[1],c=a[2]===`]`,l=a[3];if(c&&(s|=0),l===void 0||l===`[`&&o+2===i){uo(n,l===void 0?new oo(s,e,t):new so(s,e,t));break}{let e=n.map[s];e===void 0&&(e=new co(s),uo(n,e)),n=e}}}var po=class{constructor(e,t){this.seq=[],this.map={};let n=e.getProgramParameter(t,e.ACTIVE_UNIFORMS);for(let r=0;r<n;++r){let n=e.getActiveUniform(t,r);fo(n,e.getUniformLocation(t,n.name),this)}}setValue(e,t,n,r){let i=this.map[t];i!==void 0&&i.setValue(e,n,r)}setOptional(e,t,n){let r=t[n];r!==void 0&&this.setValue(e,n,r)}static upload(e,t,n,r){for(let i=0,a=t.length;i!==a;++i){let a=t[i],o=n[a.id];o.needsUpdate!==!1&&a.setValue(e,o.value,r)}}static seqWithValue(e,t){let n=[];for(let r=0,i=e.length;r!==i;++r){let i=e[r];i.id in t&&n.push(i)}return n}};function mo(e,t,n){let r=e.createShader(t);return e.shaderSource(r,n),e.compileShader(r),r}var ho=37297,go=0;function _o(e,t){let n=e.split(`
`),r=[],i=Math.max(t-6,0),a=Math.min(t+6,n.length);for(let e=i;e<a;e++){let i=e+1;r.push(`${i===t?`>`:` `} ${i}: ${n[e]}`)}return r.join(`
`)}var vo=new z;function yo(e){Ot._getMatrix(vo,Ot.workingColorSpace,e);let t=`mat3( ${vo.elements.map(e=>e.toFixed(4))} )`;switch(Ot.getTransfer(e)){case Be:return[t,`LinearTransferOETF`];case Ve:return[t,`sRGBTransferOETF`];default:return console.warn(`THREE.WebGLProgram: Unsupported color space: `,e),[t,`LinearTransferOETF`]}}function bo(e,t,n){let r=e.getShaderParameter(t,e.COMPILE_STATUS),i=e.getShaderInfoLog(t).trim();if(r&&i===``)return``;let a=/ERROR: 0:(\d+)/.exec(i);if(a){let r=parseInt(a[1]);return n.toUpperCase()+`

`+i+`

`+_o(e.getShaderSource(t),r)}return i}function xo(e,t){let n=yo(t);return[`vec4 ${e}( vec4 value ) {`,`	return ${n[1]}( vec4( value.rgb * ${n[0]}, value.a ) );`,`}`].join(`
`)}function So(e,t){let n;switch(t){case 1:n=`Linear`;break;case 2:n=`Reinhard`;break;case 3:n=`Cineon`;break;case 4:n=`ACESFilmic`;break;case 6:n=`AgX`;break;case 7:n=`Neutral`;break;case 5:n=`Custom`;break;default:console.warn(`THREE.WebGLProgram: Unsupported toneMapping:`,t),n=`Linear`}return`vec3 `+e+`( vec3 color ) { return `+n+`ToneMapping( color ); }`}var Co=new H;function wo(){return Ot.getLuminanceCoefficients(Co),[`float luminance( const in vec3 rgb ) {`,`	const vec3 weights = vec3( ${Co.x.toFixed(4)}, ${Co.y.toFixed(4)}, ${Co.z.toFixed(4)} );`,`	return dot( weights, rgb );`,`}`].join(`
`)}function To(e){return[e.extensionClipCullDistance?`#extension GL_ANGLE_clip_cull_distance : require`:``,e.extensionMultiDraw?`#extension GL_ANGLE_multi_draw : require`:``].filter(Oo).join(`
`)}function Eo(e){let t=[];for(let n in e){let r=e[n];r!==!1&&t.push(`#define `+n+` `+r)}return t.join(`
`)}function Do(e,t){let n={},r=e.getProgramParameter(t,e.ACTIVE_ATTRIBUTES);for(let i=0;i<r;i++){let r=e.getActiveAttrib(t,i),a=r.name,o=1;r.type===e.FLOAT_MAT2&&(o=2),r.type===e.FLOAT_MAT3&&(o=3),r.type===e.FLOAT_MAT4&&(o=4),n[a]={type:r.type,location:e.getAttribLocation(t,a),locationSize:o}}return n}function Oo(e){return e!==``}function ko(e,t){let n=t.numSpotLightShadows+t.numSpotLightMaps-t.numSpotLightShadowsWithMaps;return e.replace(/NUM_DIR_LIGHTS/g,t.numDirLights).replace(/NUM_SPOT_LIGHTS/g,t.numSpotLights).replace(/NUM_SPOT_LIGHT_MAPS/g,t.numSpotLightMaps).replace(/NUM_SPOT_LIGHT_COORDS/g,n).replace(/NUM_RECT_AREA_LIGHTS/g,t.numRectAreaLights).replace(/NUM_POINT_LIGHTS/g,t.numPointLights).replace(/NUM_HEMI_LIGHTS/g,t.numHemiLights).replace(/NUM_DIR_LIGHT_SHADOWS/g,t.numDirLightShadows).replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g,t.numSpotLightShadowsWithMaps).replace(/NUM_SPOT_LIGHT_SHADOWS/g,t.numSpotLightShadows).replace(/NUM_POINT_LIGHT_SHADOWS/g,t.numPointLightShadows)}function Ao(e,t){return e.replace(/NUM_CLIPPING_PLANES/g,t.numClippingPlanes).replace(/UNION_CLIPPING_PLANES/g,t.numClippingPlanes-t.numClipIntersection)}var jo=/^[ \t]*#include +<([\w\d./]+)>/gm;function Mo(e){return e.replace(jo,Po)}var No=new Map;function Po(e,t){let n=G[t];if(n===void 0){let e=No.get(t);if(e!==void 0)n=G[e],console.warn(`THREE.WebGLRenderer: Shader chunk "%s" has been deprecated. Use "%s" instead.`,t,e);else throw Error(`Can not resolve #include <`+t+`>`)}return Mo(n)}var Fo=/#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end/g;function Io(e){return e.replace(Fo,Lo)}function Lo(e,t,n,r){let i=``;for(let e=parseInt(t);e<parseInt(n);e++)i+=r.replace(/\[\s*i\s*\]/g,`[ `+e+` ]`).replace(/UNROLLED_LOOP_INDEX/g,e);return i}function Ro(e){let t=`precision ${e.precision} float;
	precision ${e.precision} int;
	precision ${e.precision} sampler2D;
	precision ${e.precision} samplerCube;
	precision ${e.precision} sampler3D;
	precision ${e.precision} sampler2DArray;
	precision ${e.precision} sampler2DShadow;
	precision ${e.precision} samplerCubeShadow;
	precision ${e.precision} sampler2DArrayShadow;
	precision ${e.precision} isampler2D;
	precision ${e.precision} isampler3D;
	precision ${e.precision} isamplerCube;
	precision ${e.precision} isampler2DArray;
	precision ${e.precision} usampler2D;
	precision ${e.precision} usampler3D;
	precision ${e.precision} usamplerCube;
	precision ${e.precision} usampler2DArray;
	`;return e.precision===`highp`?t+=`
#define HIGH_PRECISION`:e.precision===`mediump`?t+=`
#define MEDIUM_PRECISION`:e.precision===`lowp`&&(t+=`
#define LOW_PRECISION`),t}function zo(e){let t=`SHADOWMAP_TYPE_BASIC`;return e.shadowMapType===1?t=`SHADOWMAP_TYPE_PCF`:e.shadowMapType===2?t=`SHADOWMAP_TYPE_PCF_SOFT`:e.shadowMapType===3&&(t=`SHADOWMAP_TYPE_VSM`),t}function Bo(e){let t=`ENVMAP_TYPE_CUBE`;if(e.envMap)switch(e.envMapMode){case 301:case 302:t=`ENVMAP_TYPE_CUBE`;break;case 306:t=`ENVMAP_TYPE_CUBE_UV`}return t}function Vo(e){let t=`ENVMAP_MODE_REFLECTION`;if(e.envMap)switch(e.envMapMode){case 302:t=`ENVMAP_MODE_REFRACTION`}return t}function Ho(e){let t=`ENVMAP_BLENDING_NONE`;if(e.envMap)switch(e.combine){case 0:t=`ENVMAP_BLENDING_MULTIPLY`;break;case 1:t=`ENVMAP_BLENDING_MIX`;break;case 2:t=`ENVMAP_BLENDING_ADD`}return t}function Uo(e){let t=e.envMapCubeUVHeight;if(t===null)return null;let n=Math.log2(t)-2,r=1/t;return{texelWidth:1/(3*Math.max(2**n,112)),texelHeight:r,maxMip:n}}function Wo(e,t,n,r){let i=e.getContext(),a=n.defines,o=n.vertexShader,s=n.fragmentShader,c=zo(n),l=Bo(n),u=Vo(n),d=Ho(n),f=Uo(n),p=To(n),m=Eo(a),h=i.createProgram(),g,_,v=n.glslVersion?`#version `+n.glslVersion+`
`:``;n.isRawShaderMaterial?(g=[`#define SHADER_TYPE `+n.shaderType,`#define SHADER_NAME `+n.shaderName,m].filter(Oo).join(`
`),g.length>0&&(g+=`
`),_=[`#define SHADER_TYPE `+n.shaderType,`#define SHADER_NAME `+n.shaderName,m].filter(Oo).join(`
`),_.length>0&&(_+=`
`)):(g=[Ro(n),`#define SHADER_TYPE `+n.shaderType,`#define SHADER_NAME `+n.shaderName,m,n.extensionClipCullDistance?`#define USE_CLIP_DISTANCE`:``,n.batching?`#define USE_BATCHING`:``,n.batchingColor?`#define USE_BATCHING_COLOR`:``,n.instancing?`#define USE_INSTANCING`:``,n.instancingColor?`#define USE_INSTANCING_COLOR`:``,n.instancingMorph?`#define USE_INSTANCING_MORPH`:``,n.useFog&&n.fog?`#define USE_FOG`:``,n.useFog&&n.fogExp2?`#define FOG_EXP2`:``,n.map?`#define USE_MAP`:``,n.envMap?`#define USE_ENVMAP`:``,n.envMap?`#define `+u:``,n.lightMap?`#define USE_LIGHTMAP`:``,n.aoMap?`#define USE_AOMAP`:``,n.bumpMap?`#define USE_BUMPMAP`:``,n.normalMap?`#define USE_NORMALMAP`:``,n.normalMapObjectSpace?`#define USE_NORMALMAP_OBJECTSPACE`:``,n.normalMapTangentSpace?`#define USE_NORMALMAP_TANGENTSPACE`:``,n.displacementMap?`#define USE_DISPLACEMENTMAP`:``,n.emissiveMap?`#define USE_EMISSIVEMAP`:``,n.anisotropy?`#define USE_ANISOTROPY`:``,n.anisotropyMap?`#define USE_ANISOTROPYMAP`:``,n.clearcoatMap?`#define USE_CLEARCOATMAP`:``,n.clearcoatRoughnessMap?`#define USE_CLEARCOAT_ROUGHNESSMAP`:``,n.clearcoatNormalMap?`#define USE_CLEARCOAT_NORMALMAP`:``,n.iridescenceMap?`#define USE_IRIDESCENCEMAP`:``,n.iridescenceThicknessMap?`#define USE_IRIDESCENCE_THICKNESSMAP`:``,n.specularMap?`#define USE_SPECULARMAP`:``,n.specularColorMap?`#define USE_SPECULAR_COLORMAP`:``,n.specularIntensityMap?`#define USE_SPECULAR_INTENSITYMAP`:``,n.roughnessMap?`#define USE_ROUGHNESSMAP`:``,n.metalnessMap?`#define USE_METALNESSMAP`:``,n.alphaMap?`#define USE_ALPHAMAP`:``,n.alphaHash?`#define USE_ALPHAHASH`:``,n.transmission?`#define USE_TRANSMISSION`:``,n.transmissionMap?`#define USE_TRANSMISSIONMAP`:``,n.thicknessMap?`#define USE_THICKNESSMAP`:``,n.sheenColorMap?`#define USE_SHEEN_COLORMAP`:``,n.sheenRoughnessMap?`#define USE_SHEEN_ROUGHNESSMAP`:``,n.mapUv?`#define MAP_UV `+n.mapUv:``,n.alphaMapUv?`#define ALPHAMAP_UV `+n.alphaMapUv:``,n.lightMapUv?`#define LIGHTMAP_UV `+n.lightMapUv:``,n.aoMapUv?`#define AOMAP_UV `+n.aoMapUv:``,n.emissiveMapUv?`#define EMISSIVEMAP_UV `+n.emissiveMapUv:``,n.bumpMapUv?`#define BUMPMAP_UV `+n.bumpMapUv:``,n.normalMapUv?`#define NORMALMAP_UV `+n.normalMapUv:``,n.displacementMapUv?`#define DISPLACEMENTMAP_UV `+n.displacementMapUv:``,n.metalnessMapUv?`#define METALNESSMAP_UV `+n.metalnessMapUv:``,n.roughnessMapUv?`#define ROUGHNESSMAP_UV `+n.roughnessMapUv:``,n.anisotropyMapUv?`#define ANISOTROPYMAP_UV `+n.anisotropyMapUv:``,n.clearcoatMapUv?`#define CLEARCOATMAP_UV `+n.clearcoatMapUv:``,n.clearcoatNormalMapUv?`#define CLEARCOAT_NORMALMAP_UV `+n.clearcoatNormalMapUv:``,n.clearcoatRoughnessMapUv?`#define CLEARCOAT_ROUGHNESSMAP_UV `+n.clearcoatRoughnessMapUv:``,n.iridescenceMapUv?`#define IRIDESCENCEMAP_UV `+n.iridescenceMapUv:``,n.iridescenceThicknessMapUv?`#define IRIDESCENCE_THICKNESSMAP_UV `+n.iridescenceThicknessMapUv:``,n.sheenColorMapUv?`#define SHEEN_COLORMAP_UV `+n.sheenColorMapUv:``,n.sheenRoughnessMapUv?`#define SHEEN_ROUGHNESSMAP_UV `+n.sheenRoughnessMapUv:``,n.specularMapUv?`#define SPECULARMAP_UV `+n.specularMapUv:``,n.specularColorMapUv?`#define SPECULAR_COLORMAP_UV `+n.specularColorMapUv:``,n.specularIntensityMapUv?`#define SPECULAR_INTENSITYMAP_UV `+n.specularIntensityMapUv:``,n.transmissionMapUv?`#define TRANSMISSIONMAP_UV `+n.transmissionMapUv:``,n.thicknessMapUv?`#define THICKNESSMAP_UV `+n.thicknessMapUv:``,n.vertexTangents&&n.flatShading===!1?`#define USE_TANGENT`:``,n.vertexColors?`#define USE_COLOR`:``,n.vertexAlphas?`#define USE_COLOR_ALPHA`:``,n.vertexUv1s?`#define USE_UV1`:``,n.vertexUv2s?`#define USE_UV2`:``,n.vertexUv3s?`#define USE_UV3`:``,n.pointsUvs?`#define USE_POINTS_UV`:``,n.flatShading?`#define FLAT_SHADED`:``,n.skinning?`#define USE_SKINNING`:``,n.morphTargets?`#define USE_MORPHTARGETS`:``,n.morphNormals&&n.flatShading===!1?`#define USE_MORPHNORMALS`:``,n.morphColors?`#define USE_MORPHCOLORS`:``,n.morphTargetsCount>0?`#define MORPHTARGETS_TEXTURE_STRIDE `+n.morphTextureStride:``,n.morphTargetsCount>0?`#define MORPHTARGETS_COUNT `+n.morphTargetsCount:``,n.doubleSided?`#define DOUBLE_SIDED`:``,n.flipSided?`#define FLIP_SIDED`:``,n.shadowMapEnabled?`#define USE_SHADOWMAP`:``,n.shadowMapEnabled?`#define `+c:``,n.sizeAttenuation?`#define USE_SIZEATTENUATION`:``,n.numLightProbes>0?`#define USE_LIGHT_PROBES`:``,n.logarithmicDepthBuffer?`#define USE_LOGDEPTHBUF`:``,n.reverseDepthBuffer?`#define USE_REVERSEDEPTHBUF`:``,`uniform mat4 modelMatrix;`,`uniform mat4 modelViewMatrix;`,`uniform mat4 projectionMatrix;`,`uniform mat4 viewMatrix;`,`uniform mat3 normalMatrix;`,`uniform vec3 cameraPosition;`,`uniform bool isOrthographic;`,`#ifdef USE_INSTANCING`,`	attribute mat4 instanceMatrix;`,`#endif`,`#ifdef USE_INSTANCING_COLOR`,`	attribute vec3 instanceColor;`,`#endif`,`#ifdef USE_INSTANCING_MORPH`,`	uniform sampler2D morphTexture;`,`#endif`,`attribute vec3 position;`,`attribute vec3 normal;`,`attribute vec2 uv;`,`#ifdef USE_UV1`,`	attribute vec2 uv1;`,`#endif`,`#ifdef USE_UV2`,`	attribute vec2 uv2;`,`#endif`,`#ifdef USE_UV3`,`	attribute vec2 uv3;`,`#endif`,`#ifdef USE_TANGENT`,`	attribute vec4 tangent;`,`#endif`,`#if defined( USE_COLOR_ALPHA )`,`	attribute vec4 color;`,`#elif defined( USE_COLOR )`,`	attribute vec3 color;`,`#endif`,`#ifdef USE_SKINNING`,`	attribute vec4 skinIndex;`,`	attribute vec4 skinWeight;`,`#endif`,`
`].filter(Oo).join(`
`),_=[Ro(n),`#define SHADER_TYPE `+n.shaderType,`#define SHADER_NAME `+n.shaderName,m,n.useFog&&n.fog?`#define USE_FOG`:``,n.useFog&&n.fogExp2?`#define FOG_EXP2`:``,n.alphaToCoverage?`#define ALPHA_TO_COVERAGE`:``,n.map?`#define USE_MAP`:``,n.matcap?`#define USE_MATCAP`:``,n.envMap?`#define USE_ENVMAP`:``,n.envMap?`#define `+l:``,n.envMap?`#define `+u:``,n.envMap?`#define `+d:``,f?`#define CUBEUV_TEXEL_WIDTH `+f.texelWidth:``,f?`#define CUBEUV_TEXEL_HEIGHT `+f.texelHeight:``,f?`#define CUBEUV_MAX_MIP `+f.maxMip+`.0`:``,n.lightMap?`#define USE_LIGHTMAP`:``,n.aoMap?`#define USE_AOMAP`:``,n.bumpMap?`#define USE_BUMPMAP`:``,n.normalMap?`#define USE_NORMALMAP`:``,n.normalMapObjectSpace?`#define USE_NORMALMAP_OBJECTSPACE`:``,n.normalMapTangentSpace?`#define USE_NORMALMAP_TANGENTSPACE`:``,n.emissiveMap?`#define USE_EMISSIVEMAP`:``,n.anisotropy?`#define USE_ANISOTROPY`:``,n.anisotropyMap?`#define USE_ANISOTROPYMAP`:``,n.clearcoat?`#define USE_CLEARCOAT`:``,n.clearcoatMap?`#define USE_CLEARCOATMAP`:``,n.clearcoatRoughnessMap?`#define USE_CLEARCOAT_ROUGHNESSMAP`:``,n.clearcoatNormalMap?`#define USE_CLEARCOAT_NORMALMAP`:``,n.dispersion?`#define USE_DISPERSION`:``,n.iridescence?`#define USE_IRIDESCENCE`:``,n.iridescenceMap?`#define USE_IRIDESCENCEMAP`:``,n.iridescenceThicknessMap?`#define USE_IRIDESCENCE_THICKNESSMAP`:``,n.specularMap?`#define USE_SPECULARMAP`:``,n.specularColorMap?`#define USE_SPECULAR_COLORMAP`:``,n.specularIntensityMap?`#define USE_SPECULAR_INTENSITYMAP`:``,n.roughnessMap?`#define USE_ROUGHNESSMAP`:``,n.metalnessMap?`#define USE_METALNESSMAP`:``,n.alphaMap?`#define USE_ALPHAMAP`:``,n.alphaTest?`#define USE_ALPHATEST`:``,n.alphaHash?`#define USE_ALPHAHASH`:``,n.sheen?`#define USE_SHEEN`:``,n.sheenColorMap?`#define USE_SHEEN_COLORMAP`:``,n.sheenRoughnessMap?`#define USE_SHEEN_ROUGHNESSMAP`:``,n.transmission?`#define USE_TRANSMISSION`:``,n.transmissionMap?`#define USE_TRANSMISSIONMAP`:``,n.thicknessMap?`#define USE_THICKNESSMAP`:``,n.vertexTangents&&n.flatShading===!1?`#define USE_TANGENT`:``,n.vertexColors||n.instancingColor||n.batchingColor?`#define USE_COLOR`:``,n.vertexAlphas?`#define USE_COLOR_ALPHA`:``,n.vertexUv1s?`#define USE_UV1`:``,n.vertexUv2s?`#define USE_UV2`:``,n.vertexUv3s?`#define USE_UV3`:``,n.pointsUvs?`#define USE_POINTS_UV`:``,n.gradientMap?`#define USE_GRADIENTMAP`:``,n.flatShading?`#define FLAT_SHADED`:``,n.doubleSided?`#define DOUBLE_SIDED`:``,n.flipSided?`#define FLIP_SIDED`:``,n.shadowMapEnabled?`#define USE_SHADOWMAP`:``,n.shadowMapEnabled?`#define `+c:``,n.premultipliedAlpha?`#define PREMULTIPLIED_ALPHA`:``,n.numLightProbes>0?`#define USE_LIGHT_PROBES`:``,n.decodeVideoTexture?`#define DECODE_VIDEO_TEXTURE`:``,n.decodeVideoTextureEmissive?`#define DECODE_VIDEO_TEXTURE_EMISSIVE`:``,n.logarithmicDepthBuffer?`#define USE_LOGDEPTHBUF`:``,n.reverseDepthBuffer?`#define USE_REVERSEDEPTHBUF`:``,`uniform mat4 viewMatrix;`,`uniform vec3 cameraPosition;`,`uniform bool isOrthographic;`,n.toneMapping===0?``:`#define TONE_MAPPING`,n.toneMapping===0?``:G.tonemapping_pars_fragment,n.toneMapping===0?``:So(`toneMapping`,n.toneMapping),n.dithering?`#define DITHERING`:``,n.opaque?`#define OPAQUE`:``,G.colorspace_pars_fragment,xo(`linearToOutputTexel`,n.outputColorSpace),wo(),n.useDepthPacking?`#define DEPTH_PACKING `+n.depthPacking:``,`
`].filter(Oo).join(`
`)),o=Mo(o),o=ko(o,n),o=Ao(o,n),s=Mo(s),s=ko(s,n),s=Ao(s,n),o=Io(o),s=Io(s),n.isRawShaderMaterial!==!0&&(v=`#version 300 es
`,g=[p,`#define attribute in`,`#define varying out`,`#define texture2D texture`].join(`
`)+`
`+g,_=[`#define varying in`,n.glslVersion===`300 es`?``:`layout(location = 0) out highp vec4 pc_fragColor;`,n.glslVersion===`300 es`?``:`#define gl_FragColor pc_fragColor`,`#define gl_FragDepthEXT gl_FragDepth`,`#define texture2D texture`,`#define textureCube texture`,`#define texture2DProj textureProj`,`#define texture2DLodEXT textureLod`,`#define texture2DProjLodEXT textureProjLod`,`#define textureCubeLodEXT textureLod`,`#define texture2DGradEXT textureGrad`,`#define texture2DProjGradEXT textureProjGrad`,`#define textureCubeGradEXT textureGrad`].join(`
`)+`
`+_);let y=v+g+o,b=v+_+s,x=mo(i,i.VERTEX_SHADER,y),S=mo(i,i.FRAGMENT_SHADER,b);i.attachShader(h,x),i.attachShader(h,S),n.index0AttributeName===void 0?n.morphTargets===!0&&i.bindAttribLocation(h,0,`position`):i.bindAttribLocation(h,0,n.index0AttributeName),i.linkProgram(h);function C(t){if(e.debug.checkShaderErrors){let n=i.getProgramInfoLog(h).trim(),r=i.getShaderInfoLog(x).trim(),a=i.getShaderInfoLog(S).trim(),o=!0,s=!0;if(i.getProgramParameter(h,i.LINK_STATUS)===!1){if(o=!1,typeof e.debug.onShaderError==`function`)e.debug.onShaderError(i,h,x,S);else{let e=bo(i,x,`vertex`),r=bo(i,S,`fragment`);console.error(`THREE.WebGLProgram: Shader Error `+i.getError()+` - VALIDATE_STATUS `+i.getProgramParameter(h,i.VALIDATE_STATUS)+`

Material Name: `+t.name+`
Material Type: `+t.type+`

Program Info Log: `+n+`
`+e+`
`+r)}}else n===``?(r===``||a===``)&&(s=!1):console.warn(`THREE.WebGLProgram: Program Info Log:`,n);s&&(t.diagnostics={runnable:o,programLog:n,vertexShader:{log:r,prefix:g},fragmentShader:{log:a,prefix:_}})}i.deleteShader(x),i.deleteShader(S),w=new po(i,h),T=Do(i,h)}let w;this.getUniforms=function(){return w===void 0&&C(this),w};let T;this.getAttributes=function(){return T===void 0&&C(this),T};let E=n.rendererExtensionParallelShaderCompile===!1;return this.isReady=function(){return E===!1&&(E=i.getProgramParameter(h,ho)),E},this.destroy=function(){r.releaseStatesOfProgram(this),i.deleteProgram(h),this.program=void 0},this.type=n.shaderType,this.name=n.shaderName,this.id=go++,this.cacheKey=t,this.usedTimes=1,this.program=h,this.vertexShader=x,this.fragmentShader=S,this}var Go=0,Ko=class{constructor(){this.shaderCache=new Map,this.materialCache=new Map}update(e){let t=e.vertexShader,n=e.fragmentShader,r=this._getShaderStage(t),i=this._getShaderStage(n),a=this._getShaderCacheForMaterial(e);return a.has(r)===!1&&(a.add(r),r.usedTimes++),a.has(i)===!1&&(a.add(i),i.usedTimes++),this}remove(e){let t=this.materialCache.get(e);for(let e of t)e.usedTimes--,e.usedTimes===0&&this.shaderCache.delete(e.code);return this.materialCache.delete(e),this}getVertexShaderID(e){return this._getShaderStage(e.vertexShader).id}getFragmentShaderID(e){return this._getShaderStage(e.fragmentShader).id}dispose(){this.shaderCache.clear(),this.materialCache.clear()}_getShaderCacheForMaterial(e){let t=this.materialCache,n=t.get(e);return n===void 0&&(n=new Set,t.set(e,n)),n}_getShaderStage(e){let t=this.shaderCache,n=t.get(e);return n===void 0&&(n=new qo(e),t.set(e,n)),n}},qo=class{constructor(e){this.id=Go++,this.code=e,this.usedTimes=0}};function Jo(e,t,n,r,i,a,o){let s=new Nn,c=new Ko,l=new Set,u=[],d=i.logarithmicDepthBuffer,f=i.vertexTextures,p=i.precision,m={MeshDepthMaterial:`depth`,MeshDistanceMaterial:`distanceRGBA`,MeshNormalMaterial:`normal`,MeshBasicMaterial:`basic`,MeshLambertMaterial:`lambert`,MeshPhongMaterial:`phong`,MeshToonMaterial:`toon`,MeshStandardMaterial:`physical`,MeshPhysicalMaterial:`physical`,MeshMatcapMaterial:`matcap`,LineBasicMaterial:`basic`,LineDashedMaterial:`dashed`,PointsMaterial:`points`,ShadowMaterial:`shadow`,SpriteMaterial:`sprite`};function h(e){return l.add(e),e===0?`uv`:`uv${e}`}function g(a,s,u,g,_){let v=g.fog,y=_.geometry,b=a.isMeshStandardMaterial?g.environment:null,x=(a.isMeshStandardMaterial?n:t).get(a.envMap||b),S=x&&x.mapping===306?x.image.height:null,C=m[a.type];a.precision!==null&&(p=i.getMaxPrecision(a.precision),p!==a.precision&&console.warn(`THREE.WebGLProgram.getParameters:`,a.precision,`not supported, using`,p,`instead.`));let w=y.morphAttributes.position||y.morphAttributes.normal||y.morphAttributes.color,T=w===void 0?0:w.length,E=0;y.morphAttributes.position!==void 0&&(E=1),y.morphAttributes.normal!==void 0&&(E=2),y.morphAttributes.color!==void 0&&(E=3);let D,O,k,ee;if(C){let e=xi[C];D=e.vertexShader,O=e.fragmentShader}else D=a.vertexShader,O=a.fragmentShader,c.update(a),k=c.getVertexShaderID(a),ee=c.getFragmentShaderID(a);let A=e.getRenderTarget(),te=e.state.buffers.depth.getReversed(),ne=_.isInstancedMesh===!0,j=_.isBatchedMesh===!0,M=!!a.map,N=!!a.matcap,re=!!x,ie=!!a.aoMap,ae=!!a.lightMap,oe=!!a.bumpMap,se=!!a.normalMap,ce=!!a.displacementMap,le=!!a.emissiveMap,ue=!!a.metalnessMap,de=!!a.roughnessMap,fe=a.anisotropy>0,pe=a.clearcoat>0,me=a.dispersion>0,he=a.iridescence>0,ge=a.sheen>0,_e=a.transmission>0,P=fe&&!!a.anisotropyMap,ve=pe&&!!a.clearcoatMap,ye=pe&&!!a.clearcoatNormalMap,be=pe&&!!a.clearcoatRoughnessMap,F=he&&!!a.iridescenceMap,xe=he&&!!a.iridescenceThicknessMap,I=ge&&!!a.sheenColorMap,L=ge&&!!a.sheenRoughnessMap,Se=!!a.specularMap,Ce=!!a.specularColorMap,we=!!a.specularIntensityMap,Te=_e&&!!a.transmissionMap,Ee=_e&&!!a.thicknessMap,De=!!a.gradientMap,Oe=!!a.alphaMap,ke=a.alphaTest>0,Ae=!!a.alphaHash,je=!!a.extensions,Me=0;a.toneMapped&&(A===null||A.isXRRenderTarget===!0)&&(Me=e.toneMapping);let Ne={shaderID:C,shaderType:a.type,shaderName:a.name,vertexShader:D,fragmentShader:O,defines:a.defines,customVertexShaderID:k,customFragmentShaderID:ee,isRawShaderMaterial:a.isRawShaderMaterial===!0,glslVersion:a.glslVersion,precision:p,batching:j,batchingColor:j&&_._colorsTexture!==null,instancing:ne,instancingColor:ne&&_.instanceColor!==null,instancingMorph:ne&&_.morphTexture!==null,supportsVertexTextures:f,outputColorSpace:A===null?e.outputColorSpace:A.isXRRenderTarget===!0?A.texture.colorSpace:ze,alphaToCoverage:!!a.alphaToCoverage,map:M,matcap:N,envMap:re,envMapMode:re&&x.mapping,envMapCubeUVHeight:S,aoMap:ie,lightMap:ae,bumpMap:oe,normalMap:se,displacementMap:f&&ce,emissiveMap:le,normalMapObjectSpace:se&&a.normalMapType===1,normalMapTangentSpace:se&&a.normalMapType===0,metalnessMap:ue,roughnessMap:de,anisotropy:fe,anisotropyMap:P,clearcoat:pe,clearcoatMap:ve,clearcoatNormalMap:ye,clearcoatRoughnessMap:be,dispersion:me,iridescence:he,iridescenceMap:F,iridescenceThicknessMap:xe,sheen:ge,sheenColorMap:I,sheenRoughnessMap:L,specularMap:Se,specularColorMap:Ce,specularIntensityMap:we,transmission:_e,transmissionMap:Te,thicknessMap:Ee,gradientMap:De,opaque:a.transparent===!1&&a.blending===1&&a.alphaToCoverage===!1,alphaMap:Oe,alphaTest:ke,alphaHash:Ae,combine:a.combine,mapUv:M&&h(a.map.channel),aoMapUv:ie&&h(a.aoMap.channel),lightMapUv:ae&&h(a.lightMap.channel),bumpMapUv:oe&&h(a.bumpMap.channel),normalMapUv:se&&h(a.normalMap.channel),displacementMapUv:ce&&h(a.displacementMap.channel),emissiveMapUv:le&&h(a.emissiveMap.channel),metalnessMapUv:ue&&h(a.metalnessMap.channel),roughnessMapUv:de&&h(a.roughnessMap.channel),anisotropyMapUv:P&&h(a.anisotropyMap.channel),clearcoatMapUv:ve&&h(a.clearcoatMap.channel),clearcoatNormalMapUv:ye&&h(a.clearcoatNormalMap.channel),clearcoatRoughnessMapUv:be&&h(a.clearcoatRoughnessMap.channel),iridescenceMapUv:F&&h(a.iridescenceMap.channel),iridescenceThicknessMapUv:xe&&h(a.iridescenceThicknessMap.channel),sheenColorMapUv:I&&h(a.sheenColorMap.channel),sheenRoughnessMapUv:L&&h(a.sheenRoughnessMap.channel),specularMapUv:Se&&h(a.specularMap.channel),specularColorMapUv:Ce&&h(a.specularColorMap.channel),specularIntensityMapUv:we&&h(a.specularIntensityMap.channel),transmissionMapUv:Te&&h(a.transmissionMap.channel),thicknessMapUv:Ee&&h(a.thicknessMap.channel),alphaMapUv:Oe&&h(a.alphaMap.channel),vertexTangents:!!y.attributes.tangent&&(se||fe),vertexColors:a.vertexColors,vertexAlphas:a.vertexColors===!0&&!!y.attributes.color&&y.attributes.color.itemSize===4,pointsUvs:_.isPoints===!0&&!!y.attributes.uv&&(M||Oe),fog:!!v,useFog:a.fog===!0,fogExp2:!!v&&v.isFogExp2,flatShading:a.flatShading===!0,sizeAttenuation:a.sizeAttenuation===!0,logarithmicDepthBuffer:d,reverseDepthBuffer:te,skinning:_.isSkinnedMesh===!0,morphTargets:y.morphAttributes.position!==void 0,morphNormals:y.morphAttributes.normal!==void 0,morphColors:y.morphAttributes.color!==void 0,morphTargetsCount:T,morphTextureStride:E,numDirLights:s.directional.length,numPointLights:s.point.length,numSpotLights:s.spot.length,numSpotLightMaps:s.spotLightMap.length,numRectAreaLights:s.rectArea.length,numHemiLights:s.hemi.length,numDirLightShadows:s.directionalShadowMap.length,numPointLightShadows:s.pointShadowMap.length,numSpotLightShadows:s.spotShadowMap.length,numSpotLightShadowsWithMaps:s.numSpotLightShadowsWithMaps,numLightProbes:s.numLightProbes,numClippingPlanes:o.numPlanes,numClipIntersection:o.numIntersection,dithering:a.dithering,shadowMapEnabled:e.shadowMap.enabled&&u.length>0,shadowMapType:e.shadowMap.type,toneMapping:Me,decodeVideoTexture:M&&a.map.isVideoTexture===!0&&Ot.getTransfer(a.map.colorSpace)===`srgb`,decodeVideoTextureEmissive:le&&a.emissiveMap.isVideoTexture===!0&&Ot.getTransfer(a.emissiveMap.colorSpace)===`srgb`,premultipliedAlpha:a.premultipliedAlpha,doubleSided:a.side===2,flipSided:a.side===1,useDepthPacking:a.depthPacking>=0,depthPacking:a.depthPacking||0,index0AttributeName:a.index0AttributeName,extensionClipCullDistance:je&&a.extensions.clipCullDistance===!0&&r.has(`WEBGL_clip_cull_distance`),extensionMultiDraw:(je&&a.extensions.multiDraw===!0||j)&&r.has(`WEBGL_multi_draw`),rendererExtensionParallelShaderCompile:r.has(`KHR_parallel_shader_compile`),customProgramCacheKey:a.customProgramCacheKey()};return Ne.vertexUv1s=l.has(1),Ne.vertexUv2s=l.has(2),Ne.vertexUv3s=l.has(3),l.clear(),Ne}function _(t){let n=[];if(t.shaderID?n.push(t.shaderID):(n.push(t.customVertexShaderID),n.push(t.customFragmentShaderID)),t.defines!==void 0)for(let e in t.defines)n.push(e),n.push(t.defines[e]);return t.isRawShaderMaterial===!1&&(v(n,t),y(n,t),n.push(e.outputColorSpace)),n.push(t.customProgramCacheKey),n.join()}function v(e,t){e.push(t.precision),e.push(t.outputColorSpace),e.push(t.envMapMode),e.push(t.envMapCubeUVHeight),e.push(t.mapUv),e.push(t.alphaMapUv),e.push(t.lightMapUv),e.push(t.aoMapUv),e.push(t.bumpMapUv),e.push(t.normalMapUv),e.push(t.displacementMapUv),e.push(t.emissiveMapUv),e.push(t.metalnessMapUv),e.push(t.roughnessMapUv),e.push(t.anisotropyMapUv),e.push(t.clearcoatMapUv),e.push(t.clearcoatNormalMapUv),e.push(t.clearcoatRoughnessMapUv),e.push(t.iridescenceMapUv),e.push(t.iridescenceThicknessMapUv),e.push(t.sheenColorMapUv),e.push(t.sheenRoughnessMapUv),e.push(t.specularMapUv),e.push(t.specularColorMapUv),e.push(t.specularIntensityMapUv),e.push(t.transmissionMapUv),e.push(t.thicknessMapUv),e.push(t.combine),e.push(t.fogExp2),e.push(t.sizeAttenuation),e.push(t.morphTargetsCount),e.push(t.morphAttributeCount),e.push(t.numDirLights),e.push(t.numPointLights),e.push(t.numSpotLights),e.push(t.numSpotLightMaps),e.push(t.numHemiLights),e.push(t.numRectAreaLights),e.push(t.numDirLightShadows),e.push(t.numPointLightShadows),e.push(t.numSpotLightShadows),e.push(t.numSpotLightShadowsWithMaps),e.push(t.numLightProbes),e.push(t.shadowMapType),e.push(t.toneMapping),e.push(t.numClippingPlanes),e.push(t.numClipIntersection),e.push(t.depthPacking)}function y(e,t){s.disableAll(),t.supportsVertexTextures&&s.enable(0),t.instancing&&s.enable(1),t.instancingColor&&s.enable(2),t.instancingMorph&&s.enable(3),t.matcap&&s.enable(4),t.envMap&&s.enable(5),t.normalMapObjectSpace&&s.enable(6),t.normalMapTangentSpace&&s.enable(7),t.clearcoat&&s.enable(8),t.iridescence&&s.enable(9),t.alphaTest&&s.enable(10),t.vertexColors&&s.enable(11),t.vertexAlphas&&s.enable(12),t.vertexUv1s&&s.enable(13),t.vertexUv2s&&s.enable(14),t.vertexUv3s&&s.enable(15),t.vertexTangents&&s.enable(16),t.anisotropy&&s.enable(17),t.alphaHash&&s.enable(18),t.batching&&s.enable(19),t.dispersion&&s.enable(20),t.batchingColor&&s.enable(21),e.push(s.mask),s.disableAll(),t.fog&&s.enable(0),t.useFog&&s.enable(1),t.flatShading&&s.enable(2),t.logarithmicDepthBuffer&&s.enable(3),t.reverseDepthBuffer&&s.enable(4),t.skinning&&s.enable(5),t.morphTargets&&s.enable(6),t.morphNormals&&s.enable(7),t.morphColors&&s.enable(8),t.premultipliedAlpha&&s.enable(9),t.shadowMapEnabled&&s.enable(10),t.doubleSided&&s.enable(11),t.flipSided&&s.enable(12),t.useDepthPacking&&s.enable(13),t.dithering&&s.enable(14),t.transmission&&s.enable(15),t.sheen&&s.enable(16),t.opaque&&s.enable(17),t.pointsUvs&&s.enable(18),t.decodeVideoTexture&&s.enable(19),t.decodeVideoTextureEmissive&&s.enable(20),t.alphaToCoverage&&s.enable(21),e.push(s.mask)}function b(e){let t=m[e.type],n;if(t){let e=xi[t];n=Zr.clone(e.uniforms)}else n=e.uniforms;return n}function x(t,n){let r;for(let e=0,t=u.length;e<t;e++){let t=u[e];if(t.cacheKey===n){r=t,++r.usedTimes;break}}return r===void 0&&(r=new Wo(e,n,t,a),u.push(r)),r}function S(e){if(--e.usedTimes===0){let t=u.indexOf(e);u[t]=u[u.length-1],u.pop(),e.destroy()}}function C(e){c.remove(e)}function w(){c.dispose()}return{getParameters:g,getProgramCacheKey:_,getUniforms:b,acquireProgram:x,releaseProgram:S,releaseShaderCache:C,programs:u,dispose:w}}function Yo(){let e=new WeakMap;function t(t){return e.has(t)}function n(t){let n=e.get(t);return n===void 0&&(n={},e.set(t,n)),n}function r(t){e.delete(t)}function i(t,n,r){e.get(t)[n]=r}function a(){e=new WeakMap}return{has:t,get:n,remove:r,update:i,dispose:a}}function Xo(e,t){return e.groupOrder===t.groupOrder?e.renderOrder===t.renderOrder?e.material.id===t.material.id?e.z===t.z?e.id-t.id:e.z-t.z:e.material.id-t.material.id:e.renderOrder-t.renderOrder:e.groupOrder-t.groupOrder}function Zo(e,t){return e.groupOrder===t.groupOrder?e.renderOrder===t.renderOrder?e.z===t.z?e.id-t.id:t.z-e.z:e.renderOrder-t.renderOrder:e.groupOrder-t.groupOrder}function Qo(){let e=[],t=0,n=[],r=[],i=[];function a(){t=0,n.length=0,r.length=0,i.length=0}function o(n,r,i,a,o,s){let c=e[t];return c===void 0?(c={id:n.id,object:n,geometry:r,material:i,groupOrder:a,renderOrder:n.renderOrder,z:o,group:s},e[t]=c):(c.id=n.id,c.object=n,c.geometry=r,c.material=i,c.groupOrder=a,c.renderOrder=n.renderOrder,c.z=o,c.group=s),t++,c}function s(e,t,a,s,c,l){let u=o(e,t,a,s,c,l);a.transmission>0?r.push(u):a.transparent===!0?i.push(u):n.push(u)}function c(e,t,a,s,c,l){let u=o(e,t,a,s,c,l);a.transmission>0?r.unshift(u):a.transparent===!0?i.unshift(u):n.unshift(u)}function l(e,t){n.length>1&&n.sort(e||Xo),r.length>1&&r.sort(t||Zo),i.length>1&&i.sort(t||Zo)}function u(){for(let n=t,r=e.length;n<r;n++){let t=e[n];if(t.id===null)break;t.id=null,t.object=null,t.geometry=null,t.material=null,t.group=null}}return{opaque:n,transmissive:r,transparent:i,init:a,push:s,unshift:c,finish:u,sort:l}}function $o(){let e=new WeakMap;function t(t,n){let r=e.get(t),i;return r===void 0?(i=new Qo,e.set(t,[i])):n>=r.length?(i=new Qo,r.push(i)):i=r[n],i}function n(){e=new WeakMap}return{get:t,dispose:n}}function es(){let e={};return{get:function(t){if(e[t.id]!==void 0)return e[t.id];let n;switch(t.type){case`DirectionalLight`:n={direction:new H,color:new W};break;case`SpotLight`:n={position:new H,direction:new H,color:new W,distance:0,coneCos:0,penumbraCos:0,decay:0};break;case`PointLight`:n={position:new H,color:new W,distance:0,decay:0};break;case`HemisphereLight`:n={direction:new H,skyColor:new W,groundColor:new W};break;case`RectAreaLight`:n={color:new W,position:new H,halfWidth:new H,halfHeight:new H}}return e[t.id]=n,n}}}function ts(){let e={};return{get:function(t){if(e[t.id]!==void 0)return e[t.id];let n;switch(t.type){case`DirectionalLight`:n={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new R};break;case`SpotLight`:n={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new R};break;case`PointLight`:n={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new R,shadowCameraNear:1,shadowCameraFar:1e3}}return e[t.id]=n,n}}}var ns=0;function rs(e,t){return(t.castShadow?2:0)-(e.castShadow?2:0)+ +!!t.map-!!e.map}function is(e){let t=new es,n=ts(),r={version:0,hash:{directionalLength:-1,pointLength:-1,spotLength:-1,rectAreaLength:-1,hemiLength:-1,numDirectionalShadows:-1,numPointShadows:-1,numSpotShadows:-1,numSpotMaps:-1,numLightProbes:-1},ambient:[0,0,0],probe:[],directional:[],directionalShadow:[],directionalShadowMap:[],directionalShadowMatrix:[],spot:[],spotLightMap:[],spotShadow:[],spotShadowMap:[],spotLightMatrix:[],rectArea:[],rectAreaLTC1:null,rectAreaLTC2:null,point:[],pointShadow:[],pointShadowMap:[],pointShadowMatrix:[],hemi:[],numSpotLightShadowsWithMaps:0,numLightProbes:0};for(let e=0;e<9;e++)r.probe.push(new H);let i=new H,a=new U,o=new U;function s(i){let a=0,o=0,s=0;for(let e=0;e<9;e++)r.probe[e].set(0,0,0);let c=0,l=0,u=0,d=0,f=0,p=0,m=0,h=0,g=0,_=0,v=0;i.sort(rs);for(let e=0,y=i.length;e<y;e++){let y=i[e],b=y.color,x=y.intensity,S=y.distance,C=y.shadow&&y.shadow.map?y.shadow.map.texture:null;if(y.isAmbientLight)a+=b.r*x,o+=b.g*x,s+=b.b*x;else if(y.isLightProbe){for(let e=0;e<9;e++)r.probe[e].addScaledVector(y.sh.coefficients[e],x);v++}else if(y.isDirectionalLight){let e=t.get(y);if(e.color.copy(y.color).multiplyScalar(y.intensity),y.castShadow){let e=y.shadow,t=n.get(y);t.shadowIntensity=e.intensity,t.shadowBias=e.bias,t.shadowNormalBias=e.normalBias,t.shadowRadius=e.radius,t.shadowMapSize=e.mapSize,r.directionalShadow[c]=t,r.directionalShadowMap[c]=C,r.directionalShadowMatrix[c]=y.shadow.matrix,p++}r.directional[c]=e,c++}else if(y.isSpotLight){let e=t.get(y);e.position.setFromMatrixPosition(y.matrixWorld),e.color.copy(b).multiplyScalar(x),e.distance=S,e.coneCos=Math.cos(y.angle),e.penumbraCos=Math.cos(y.angle*(1-y.penumbra)),e.decay=y.decay,r.spot[u]=e;let i=y.shadow;if(y.map&&(r.spotLightMap[g]=y.map,g++,i.updateMatrices(y),y.castShadow&&_++),r.spotLightMatrix[u]=i.matrix,y.castShadow){let e=n.get(y);e.shadowIntensity=i.intensity,e.shadowBias=i.bias,e.shadowNormalBias=i.normalBias,e.shadowRadius=i.radius,e.shadowMapSize=i.mapSize,r.spotShadow[u]=e,r.spotShadowMap[u]=C,h++}u++}else if(y.isRectAreaLight){let e=t.get(y);e.color.copy(b).multiplyScalar(x),e.halfWidth.set(y.width*.5,0,0),e.halfHeight.set(0,y.height*.5,0),r.rectArea[d]=e,d++}else if(y.isPointLight){let e=t.get(y);if(e.color.copy(y.color).multiplyScalar(y.intensity),e.distance=y.distance,e.decay=y.decay,y.castShadow){let e=y.shadow,t=n.get(y);t.shadowIntensity=e.intensity,t.shadowBias=e.bias,t.shadowNormalBias=e.normalBias,t.shadowRadius=e.radius,t.shadowMapSize=e.mapSize,t.shadowCameraNear=e.camera.near,t.shadowCameraFar=e.camera.far,r.pointShadow[l]=t,r.pointShadowMap[l]=C,r.pointShadowMatrix[l]=y.shadow.matrix,m++}r.point[l]=e,l++}else if(y.isHemisphereLight){let e=t.get(y);e.skyColor.copy(y.color).multiplyScalar(x),e.groundColor.copy(y.groundColor).multiplyScalar(x),r.hemi[f]=e,f++}}d>0&&(e.has(`OES_texture_float_linear`)===!0?(r.rectAreaLTC1=K.LTC_FLOAT_1,r.rectAreaLTC2=K.LTC_FLOAT_2):(r.rectAreaLTC1=K.LTC_HALF_1,r.rectAreaLTC2=K.LTC_HALF_2)),r.ambient[0]=a,r.ambient[1]=o,r.ambient[2]=s;let y=r.hash;(y.directionalLength!==c||y.pointLength!==l||y.spotLength!==u||y.rectAreaLength!==d||y.hemiLength!==f||y.numDirectionalShadows!==p||y.numPointShadows!==m||y.numSpotShadows!==h||y.numSpotMaps!==g||y.numLightProbes!==v)&&(r.directional.length=c,r.spot.length=u,r.rectArea.length=d,r.point.length=l,r.hemi.length=f,r.directionalShadow.length=p,r.directionalShadowMap.length=p,r.pointShadow.length=m,r.pointShadowMap.length=m,r.spotShadow.length=h,r.spotShadowMap.length=h,r.directionalShadowMatrix.length=p,r.pointShadowMatrix.length=m,r.spotLightMatrix.length=h+g-_,r.spotLightMap.length=g,r.numSpotLightShadowsWithMaps=_,r.numLightProbes=v,y.directionalLength=c,y.pointLength=l,y.spotLength=u,y.rectAreaLength=d,y.hemiLength=f,y.numDirectionalShadows=p,y.numPointShadows=m,y.numSpotShadows=h,y.numSpotMaps=g,y.numLightProbes=v,r.version=ns++)}function c(e,t){let n=0,s=0,c=0,l=0,u=0,d=t.matrixWorldInverse;for(let t=0,f=e.length;t<f;t++){let f=e[t];if(f.isDirectionalLight){let e=r.directional[n];e.direction.setFromMatrixPosition(f.matrixWorld),i.setFromMatrixPosition(f.target.matrixWorld),e.direction.sub(i),e.direction.transformDirection(d),n++}else if(f.isSpotLight){let e=r.spot[c];e.position.setFromMatrixPosition(f.matrixWorld),e.position.applyMatrix4(d),e.direction.setFromMatrixPosition(f.matrixWorld),i.setFromMatrixPosition(f.target.matrixWorld),e.direction.sub(i),e.direction.transformDirection(d),c++}else if(f.isRectAreaLight){let e=r.rectArea[l];e.position.setFromMatrixPosition(f.matrixWorld),e.position.applyMatrix4(d),o.identity(),a.copy(f.matrixWorld),a.premultiply(d),o.extractRotation(a),e.halfWidth.set(f.width*.5,0,0),e.halfHeight.set(0,f.height*.5,0),e.halfWidth.applyMatrix4(o),e.halfHeight.applyMatrix4(o),l++}else if(f.isPointLight){let e=r.point[s];e.position.setFromMatrixPosition(f.matrixWorld),e.position.applyMatrix4(d),s++}else if(f.isHemisphereLight){let e=r.hemi[u];e.direction.setFromMatrixPosition(f.matrixWorld),e.direction.transformDirection(d),u++}}}return{setup:s,setupView:c,state:r}}function as(e){let t=new is(e),n=[],r=[];function i(e){l.camera=e,n.length=0,r.length=0}function a(e){n.push(e)}function o(e){r.push(e)}function s(){t.setup(n)}function c(e){t.setupView(n,e)}let l={lightsArray:n,shadowsArray:r,camera:null,lights:t,transmissionRenderTarget:{}};return{init:i,state:l,setupLights:s,setupLightsView:c,pushLight:a,pushShadow:o}}function os(e){let t=new WeakMap;function n(n,r=0){let i=t.get(n),a;return i===void 0?(a=new as(e),t.set(n,[a])):r>=i.length?(a=new as(e),i.push(a)):a=i[r],a}function r(){t=new WeakMap}return{get:n,dispose:r}}var ss=class extends gr{static get type(){return`MeshDepthMaterial`}constructor(e){super(),this.isMeshDepthMaterial=!0,this.depthPacking=Ie,this.map=null,this.alphaMap=null,this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.wireframe=!1,this.wireframeLinewidth=1,this.setValues(e)}copy(e){return super.copy(e),this.depthPacking=e.depthPacking,this.map=e.map,this.alphaMap=e.alphaMap,this.displacementMap=e.displacementMap,this.displacementScale=e.displacementScale,this.displacementBias=e.displacementBias,this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this}},cs=class extends gr{static get type(){return`MeshDistanceMaterial`}constructor(e){super(),this.isMeshDistanceMaterial=!0,this.map=null,this.alphaMap=null,this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.setValues(e)}copy(e){return super.copy(e),this.map=e.map,this.alphaMap=e.alphaMap,this.displacementMap=e.displacementMap,this.displacementScale=e.displacementScale,this.displacementBias=e.displacementBias,this}},ls=`void main() {
	gl_Position = vec4( position, 1.0 );
}`,us=`uniform sampler2D shadow_pass;
uniform vec2 resolution;
uniform float radius;
#include <packing>
void main() {
	const float samples = float( VSM_SAMPLES );
	float mean = 0.0;
	float squared_mean = 0.0;
	float uvStride = samples <= 1.0 ? 0.0 : 2.0 / ( samples - 1.0 );
	float uvStart = samples <= 1.0 ? 0.0 : - 1.0;
	for ( float i = 0.0; i < samples; i ++ ) {
		float uvOffset = uvStart + i * uvStride;
		#ifdef HORIZONTAL_PASS
			vec2 distribution = unpackRGBATo2Half( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( uvOffset, 0.0 ) * radius ) / resolution ) );
			mean += distribution.x;
			squared_mean += distribution.y * distribution.y + distribution.x * distribution.x;
		#else
			float depth = unpackRGBAToDepth( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( 0.0, uvOffset ) * radius ) / resolution ) );
			mean += depth;
			squared_mean += depth * depth;
		#endif
	}
	mean = mean / samples;
	squared_mean = squared_mean / samples;
	float std_dev = sqrt( squared_mean - mean * mean );
	gl_FragColor = pack2HalfToRGBA( vec2( mean, std_dev ) );
}`;function ds(e,t,n){let r=new _i,i=new R,a=new R,s=new B,c=new ss({depthPacking:Le}),l=new cs,u={},d=n.maxTextureSize,f={0:1,1:0,2:2},p=new ei({defines:{VSM_SAMPLES:8},uniforms:{shadow_pass:{value:null},resolution:{value:new R},radius:{value:4}},vertexShader:ls,fragmentShader:us}),m=p.clone();m.defines.HORIZONTAL_PASS=1;let h=new jr;h.setAttribute(`position`,new br(new Float32Array([-1,-1,.5,3,-1,.5,-1,3,.5]),3));let g=new Ur(h,p),_=this;this.enabled=!1,this.autoUpdate=!0,this.needsUpdate=!1,this.type=1;let v=this.type;this.render=function(t,n,c){if(_.enabled===!1||_.autoUpdate===!1&&_.needsUpdate===!1||t.length===0)return;let l=e.getRenderTarget(),u=e.getActiveCubeFace(),f=e.getActiveMipmapLevel(),p=e.state;p.setBlending(0),p.buffers.color.setClear(1,1,1,1),p.buffers.depth.setTest(!0),p.setScissorTest(!1);let m=v!==3&&this.type===3,h=v===3&&this.type!==3;for(let l=0,u=t.length;l<u;l++){let u=t[l],f=u.shadow;if(f===void 0){console.warn(`THREE.WebGLShadowMap:`,u,`has no shadow.`);continue}if(f.autoUpdate===!1&&f.needsUpdate===!1)continue;i.copy(f.mapSize);let g=f.getFrameExtents();if(i.multiply(g),a.copy(f.mapSize),(i.x>d||i.y>d)&&(i.x>d&&(a.x=Math.floor(d/g.x),i.x=a.x*g.x,f.mapSize.x=a.x),i.y>d&&(a.y=Math.floor(d/g.y),i.y=a.y*g.y,f.mapSize.y=a.y)),f.map===null||m===!0||h===!0){let e=this.type===3?{}:{minFilter:o,magFilter:o};f.map!==null&&f.map.dispose(),f.map=new Wt(i.x,i.y,e),f.map.texture.name=u.name+`.shadowMap`,f.camera.updateProjectionMatrix()}e.setRenderTarget(f.map),e.clear();let _=f.getViewportCount();for(let e=0;e<_;e++){let t=f.getViewport(e);s.set(a.x*t.x,a.y*t.y,a.x*t.z,a.y*t.w),p.viewport(s),f.updateMatrices(u,e),r=f.getFrustum(),x(n,c,f.camera,u,this.type)}f.isPointLightShadow!==!0&&this.type===3&&y(f,c),f.needsUpdate=!1}v=this.type,_.needsUpdate=!1,e.setRenderTarget(l,u,f)};function y(n,r){let a=t.update(g);p.defines.VSM_SAMPLES!==n.blurSamples&&(p.defines.VSM_SAMPLES=n.blurSamples,m.defines.VSM_SAMPLES=n.blurSamples,p.needsUpdate=!0,m.needsUpdate=!0),n.mapPass===null&&(n.mapPass=new Wt(i.x,i.y)),p.uniforms.shadow_pass.value=n.map.texture,p.uniforms.resolution.value=n.mapSize,p.uniforms.radius.value=n.radius,e.setRenderTarget(n.mapPass),e.clear(),e.renderBufferDirect(r,null,a,p,g,null),m.uniforms.shadow_pass.value=n.mapPass.texture,m.uniforms.resolution.value=n.mapSize,m.uniforms.radius.value=n.radius,e.setRenderTarget(n.map),e.clear(),e.renderBufferDirect(r,null,a,m,g,null)}function b(t,n,r,i){let a=null,o=r.isPointLight===!0?t.customDistanceMaterial:t.customDepthMaterial;if(o!==void 0)a=o;else if(a=r.isPointLight===!0?l:c,e.localClippingEnabled&&n.clipShadows===!0&&Array.isArray(n.clippingPlanes)&&n.clippingPlanes.length!==0||n.displacementMap&&n.displacementScale!==0||n.alphaMap&&n.alphaTest>0||n.map&&n.alphaTest>0){let e=a.uuid,t=n.uuid,r=u[e];r===void 0&&(r={},u[e]=r);let i=r[t];i===void 0&&(i=a.clone(),r[t]=i,n.addEventListener(`dispose`,S)),a=i}if(a.visible=n.visible,a.wireframe=n.wireframe,i===3?a.side=n.shadowSide===null?n.side:n.shadowSide:a.side=n.shadowSide===null?f[n.side]:n.shadowSide,a.alphaMap=n.alphaMap,a.alphaTest=n.alphaTest,a.map=n.map,a.clipShadows=n.clipShadows,a.clippingPlanes=n.clippingPlanes,a.clipIntersection=n.clipIntersection,a.displacementMap=n.displacementMap,a.displacementScale=n.displacementScale,a.displacementBias=n.displacementBias,a.wireframeLinewidth=n.wireframeLinewidth,a.linewidth=n.linewidth,r.isPointLight===!0&&a.isMeshDistanceMaterial===!0){let t=e.properties.get(a);t.light=r}return a}function x(n,i,a,o,s){if(n.visible===!1)return;if(n.layers.test(i.layers)&&(n.isMesh||n.isLine||n.isPoints)&&(n.castShadow||n.receiveShadow&&s===3)&&(!n.frustumCulled||r.intersectsObject(n))){n.modelViewMatrix.multiplyMatrices(a.matrixWorldInverse,n.matrixWorld);let r=t.update(n),c=n.material;if(Array.isArray(c)){let t=r.groups;for(let l=0,u=t.length;l<u;l++){let u=t[l],d=c[u.materialIndex];if(d&&d.visible){let t=b(n,d,o,s);n.onBeforeShadow(e,n,i,a,r,t,u),e.renderBufferDirect(a,null,r,t,n,u),n.onAfterShadow(e,n,i,a,r,t,u)}}}else if(c.visible){let t=b(n,c,o,s);n.onBeforeShadow(e,n,i,a,r,t,null),e.renderBufferDirect(a,null,r,t,n,null),n.onAfterShadow(e,n,i,a,r,t,null)}}let c=n.children;for(let e=0,t=c.length;e<t;e++)x(c[e],i,a,o,s)}function S(e){e.target.removeEventListener(`dispose`,S);for(let t in u){let n=u[t],r=e.target.uuid;r in n&&(n[r].dispose(),delete n[r])}}}var fs={0:1,2:6,4:7,3:5,1:0,6:2,7:4,5:3};function ps(e,t){function n(){let t=!1,n=new B,r=null,i=new B(0,0,0,0);return{setMask:function(n){r!==n&&!t&&(e.colorMask(n,n,n,n),r=n)},setLocked:function(e){t=e},setClear:function(t,r,a,o,s){s===!0&&(t*=o,r*=o,a*=o),n.set(t,r,a,o),i.equals(n)===!1&&(e.clearColor(t,r,a,o),i.copy(n))},reset:function(){t=!1,r=null,i.set(-1,0,0,0)}}}function r(){let n=!1,r=!1,i=null,a=null,o=null;return{setReversed:function(e){if(r!==e){let e=t.get(`EXT_clip_control`);r?e.clipControlEXT(e.LOWER_LEFT_EXT,e.ZERO_TO_ONE_EXT):e.clipControlEXT(e.LOWER_LEFT_EXT,e.NEGATIVE_ONE_TO_ONE_EXT);let n=o;o=null,this.setClear(n)}r=e},getReversed:function(){return r},setTest:function(t){t?le(e.DEPTH_TEST):ue(e.DEPTH_TEST)},setMask:function(t){i!==t&&!n&&(e.depthMask(t),i=t)},setFunc:function(t){if(r&&(t=fs[t]),a!==t){switch(t){case 0:e.depthFunc(e.NEVER);break;case 1:e.depthFunc(e.ALWAYS);break;case 2:e.depthFunc(e.LESS);break;case 3:e.depthFunc(e.LEQUAL);break;case 4:e.depthFunc(e.EQUAL);break;case 5:e.depthFunc(e.GEQUAL);break;case 6:e.depthFunc(e.GREATER);break;case 7:e.depthFunc(e.NOTEQUAL);break;default:e.depthFunc(e.LEQUAL)}a=t}},setLocked:function(e){n=e},setClear:function(t){o!==t&&(r&&(t=1-t),e.clearDepth(t),o=t)},reset:function(){n=!1,i=null,a=null,o=null,r=!1}}}function i(){let t=!1,n=null,r=null,i=null,a=null,o=null,s=null,c=null,l=null;return{setTest:function(n){t||(n?le(e.STENCIL_TEST):ue(e.STENCIL_TEST))},setMask:function(r){n!==r&&!t&&(e.stencilMask(r),n=r)},setFunc:function(t,n,o){(r!==t||i!==n||a!==o)&&(e.stencilFunc(t,n,o),r=t,i=n,a=o)},setOp:function(t,n,r){(o!==t||s!==n||c!==r)&&(e.stencilOp(t,n,r),o=t,s=n,c=r)},setLocked:function(e){t=e},setClear:function(t){l!==t&&(e.clearStencil(t),l=t)},reset:function(){t=!1,n=null,r=null,i=null,a=null,o=null,s=null,c=null,l=null}}}let a=new n,o=new r,s=new i,c=new WeakMap,l=new WeakMap,u={},d={},f=new WeakMap,p=[],m=null,h=!1,g=null,_=null,v=null,y=null,b=null,x=null,S=null,C=new W(0,0,0),w=0,T=!1,E=null,D=null,O=null,k=null,ee=null,A=e.getParameter(e.MAX_COMBINED_TEXTURE_IMAGE_UNITS),te=!1,ne=0,j=e.getParameter(e.VERSION);j.indexOf(`WebGL`)===-1?j.indexOf(`OpenGL ES`)!==-1&&(ne=parseFloat(/^OpenGL ES (\d)/.exec(j)[1]),te=ne>=2):(ne=parseFloat(/^WebGL (\d)/.exec(j)[1]),te=ne>=1);let M=null,N={},re=e.getParameter(e.SCISSOR_BOX),ie=e.getParameter(e.VIEWPORT),ae=new B().fromArray(re),oe=new B().fromArray(ie);function se(t,n,r,i){let a=new Uint8Array(4),o=e.createTexture();e.bindTexture(t,o),e.texParameteri(t,e.TEXTURE_MIN_FILTER,e.NEAREST),e.texParameteri(t,e.TEXTURE_MAG_FILTER,e.NEAREST);for(let o=0;o<r;o++)t===e.TEXTURE_3D||t===e.TEXTURE_2D_ARRAY?e.texImage3D(n,0,e.RGBA,1,1,i,0,e.RGBA,e.UNSIGNED_BYTE,a):e.texImage2D(n+o,0,e.RGBA,1,1,0,e.RGBA,e.UNSIGNED_BYTE,a);return o}let ce={};ce[e.TEXTURE_2D]=se(e.TEXTURE_2D,e.TEXTURE_2D,1),ce[e.TEXTURE_CUBE_MAP]=se(e.TEXTURE_CUBE_MAP,e.TEXTURE_CUBE_MAP_POSITIVE_X,6),ce[e.TEXTURE_2D_ARRAY]=se(e.TEXTURE_2D_ARRAY,e.TEXTURE_2D_ARRAY,1,1),ce[e.TEXTURE_3D]=se(e.TEXTURE_3D,e.TEXTURE_3D,1,1),a.setClear(0,0,0,1),o.setClear(1),s.setClear(0),le(e.DEPTH_TEST),o.setFunc(3),P(!1),ve(1),le(e.CULL_FACE),ge(0);function le(t){u[t]!==!0&&(e.enable(t),u[t]=!0)}function ue(t){u[t]!==!1&&(e.disable(t),u[t]=!1)}function de(t,n){return d[t]!==n&&(e.bindFramebuffer(t,n),d[t]=n,t===e.DRAW_FRAMEBUFFER&&(d[e.FRAMEBUFFER]=n),t===e.FRAMEBUFFER&&(d[e.DRAW_FRAMEBUFFER]=n),!0)}function fe(t,n){let r=p,i=!1;if(t){r=f.get(n),r===void 0&&(r=[],f.set(n,r));let a=t.textures;if(r.length!==a.length||r[0]!==e.COLOR_ATTACHMENT0){for(let t=0,n=a.length;t<n;t++)r[t]=e.COLOR_ATTACHMENT0+t;r.length=a.length,i=!0}}else r[0]!==e.BACK&&(r[0]=e.BACK,i=!0);i&&e.drawBuffers(r)}function pe(t){return m!==t&&(e.useProgram(t),m=t,!0)}let me={100:e.FUNC_ADD,101:e.FUNC_SUBTRACT,102:e.FUNC_REVERSE_SUBTRACT};me[103]=e.MIN,me[104]=e.MAX;let he={200:e.ZERO,201:e.ONE,202:e.SRC_COLOR,204:e.SRC_ALPHA,210:e.SRC_ALPHA_SATURATE,208:e.DST_COLOR,206:e.DST_ALPHA,203:e.ONE_MINUS_SRC_COLOR,205:e.ONE_MINUS_SRC_ALPHA,209:e.ONE_MINUS_DST_COLOR,207:e.ONE_MINUS_DST_ALPHA,211:e.CONSTANT_COLOR,212:e.ONE_MINUS_CONSTANT_COLOR,213:e.CONSTANT_ALPHA,214:e.ONE_MINUS_CONSTANT_ALPHA};function ge(t,n,r,i,a,o,s,c,l,u){if(t===0){h===!0&&(ue(e.BLEND),h=!1);return}if(h===!1&&(le(e.BLEND),h=!0),t!==5){if(t!==g||u!==T){if((_!==100||b!==100)&&(e.blendEquation(e.FUNC_ADD),_=100,b=100),u)switch(t){case 1:e.blendFuncSeparate(e.ONE,e.ONE_MINUS_SRC_ALPHA,e.ONE,e.ONE_MINUS_SRC_ALPHA);break;case 2:e.blendFunc(e.ONE,e.ONE);break;case 3:e.blendFuncSeparate(e.ZERO,e.ONE_MINUS_SRC_COLOR,e.ZERO,e.ONE);break;case 4:e.blendFuncSeparate(e.ZERO,e.SRC_COLOR,e.ZERO,e.SRC_ALPHA);break;default:console.error(`THREE.WebGLState: Invalid blending: `,t)}else switch(t){case 1:e.blendFuncSeparate(e.SRC_ALPHA,e.ONE_MINUS_SRC_ALPHA,e.ONE,e.ONE_MINUS_SRC_ALPHA);break;case 2:e.blendFunc(e.SRC_ALPHA,e.ONE);break;case 3:e.blendFuncSeparate(e.ZERO,e.ONE_MINUS_SRC_COLOR,e.ZERO,e.ONE);break;case 4:e.blendFunc(e.ZERO,e.SRC_COLOR);break;default:console.error(`THREE.WebGLState: Invalid blending: `,t)}v=null,y=null,x=null,S=null,C.set(0,0,0),w=0,g=t,T=u}return}a||=n,o||=r,s||=i,(n!==_||a!==b)&&(e.blendEquationSeparate(me[n],me[a]),_=n,b=a),(r!==v||i!==y||o!==x||s!==S)&&(e.blendFuncSeparate(he[r],he[i],he[o],he[s]),v=r,y=i,x=o,S=s),(c.equals(C)===!1||l!==w)&&(e.blendColor(c.r,c.g,c.b,l),C.copy(c),w=l),g=t,T=!1}function _e(t,n){t.side===2?ue(e.CULL_FACE):le(e.CULL_FACE);let r=t.side===1;n&&(r=!r),P(r),t.blending===1&&t.transparent===!1?ge(0):ge(t.blending,t.blendEquation,t.blendSrc,t.blendDst,t.blendEquationAlpha,t.blendSrcAlpha,t.blendDstAlpha,t.blendColor,t.blendAlpha,t.premultipliedAlpha),o.setFunc(t.depthFunc),o.setTest(t.depthTest),o.setMask(t.depthWrite),a.setMask(t.colorWrite);let i=t.stencilWrite;s.setTest(i),i&&(s.setMask(t.stencilWriteMask),s.setFunc(t.stencilFunc,t.stencilRef,t.stencilFuncMask),s.setOp(t.stencilFail,t.stencilZFail,t.stencilZPass)),be(t.polygonOffset,t.polygonOffsetFactor,t.polygonOffsetUnits),t.alphaToCoverage===!0?le(e.SAMPLE_ALPHA_TO_COVERAGE):ue(e.SAMPLE_ALPHA_TO_COVERAGE)}function P(t){E!==t&&(t?e.frontFace(e.CW):e.frontFace(e.CCW),E=t)}function ve(t){t===0?ue(e.CULL_FACE):(le(e.CULL_FACE),t!==D&&(t===1?e.cullFace(e.BACK):t===2?e.cullFace(e.FRONT):e.cullFace(e.FRONT_AND_BACK))),D=t}function ye(t){t!==O&&(te&&e.lineWidth(t),O=t)}function be(t,n,r){t?(le(e.POLYGON_OFFSET_FILL),(k!==n||ee!==r)&&(e.polygonOffset(n,r),k=n,ee=r)):ue(e.POLYGON_OFFSET_FILL)}function F(t){t?le(e.SCISSOR_TEST):ue(e.SCISSOR_TEST)}function xe(t){t===void 0&&(t=e.TEXTURE0+A-1),M!==t&&(e.activeTexture(t),M=t)}function I(t,n,r){r===void 0&&(r=M===null?e.TEXTURE0+A-1:M);let i=N[r];i===void 0&&(i={type:void 0,texture:void 0},N[r]=i),(i.type!==t||i.texture!==n)&&(M!==r&&(e.activeTexture(r),M=r),e.bindTexture(t,n||ce[t]),i.type=t,i.texture=n)}function L(){let t=N[M];t!==void 0&&t.type!==void 0&&(e.bindTexture(t.type,null),t.type=void 0,t.texture=void 0)}function Se(){try{e.compressedTexImage2D.apply(e,arguments)}catch(e){console.error(`THREE.WebGLState:`,e)}}function Ce(){try{e.compressedTexImage3D.apply(e,arguments)}catch(e){console.error(`THREE.WebGLState:`,e)}}function we(){try{e.texSubImage2D.apply(e,arguments)}catch(e){console.error(`THREE.WebGLState:`,e)}}function Te(){try{e.texSubImage3D.apply(e,arguments)}catch(e){console.error(`THREE.WebGLState:`,e)}}function Ee(){try{e.compressedTexSubImage2D.apply(e,arguments)}catch(e){console.error(`THREE.WebGLState:`,e)}}function De(){try{e.compressedTexSubImage3D.apply(e,arguments)}catch(e){console.error(`THREE.WebGLState:`,e)}}function Oe(){try{e.texStorage2D.apply(e,arguments)}catch(e){console.error(`THREE.WebGLState:`,e)}}function ke(){try{e.texStorage3D.apply(e,arguments)}catch(e){console.error(`THREE.WebGLState:`,e)}}function Ae(){try{e.texImage2D.apply(e,arguments)}catch(e){console.error(`THREE.WebGLState:`,e)}}function je(){try{e.texImage3D.apply(e,arguments)}catch(e){console.error(`THREE.WebGLState:`,e)}}function Me(t){ae.equals(t)===!1&&(e.scissor(t.x,t.y,t.z,t.w),ae.copy(t))}function Ne(t){oe.equals(t)===!1&&(e.viewport(t.x,t.y,t.z,t.w),oe.copy(t))}function Pe(t,n){let r=l.get(n);r===void 0&&(r=new WeakMap,l.set(n,r));let i=r.get(t);i===void 0&&(i=e.getUniformBlockIndex(n,t.name),r.set(t,i))}function Fe(t,n){let r=l.get(n).get(t);c.get(n)!==r&&(e.uniformBlockBinding(n,r,t.__bindingPointIndex),c.set(n,r))}function Ie(){e.disable(e.BLEND),e.disable(e.CULL_FACE),e.disable(e.DEPTH_TEST),e.disable(e.POLYGON_OFFSET_FILL),e.disable(e.SCISSOR_TEST),e.disable(e.STENCIL_TEST),e.disable(e.SAMPLE_ALPHA_TO_COVERAGE),e.blendEquation(e.FUNC_ADD),e.blendFunc(e.ONE,e.ZERO),e.blendFuncSeparate(e.ONE,e.ZERO,e.ONE,e.ZERO),e.blendColor(0,0,0,0),e.colorMask(!0,!0,!0,!0),e.clearColor(0,0,0,0),e.depthMask(!0),e.depthFunc(e.LESS),o.setReversed(!1),e.clearDepth(1),e.stencilMask(4294967295),e.stencilFunc(e.ALWAYS,0,4294967295),e.stencilOp(e.KEEP,e.KEEP,e.KEEP),e.clearStencil(0),e.cullFace(e.BACK),e.frontFace(e.CCW),e.polygonOffset(0,0),e.activeTexture(e.TEXTURE0),e.bindFramebuffer(e.FRAMEBUFFER,null),e.bindFramebuffer(e.DRAW_FRAMEBUFFER,null),e.bindFramebuffer(e.READ_FRAMEBUFFER,null),e.useProgram(null),e.lineWidth(1),e.scissor(0,0,e.canvas.width,e.canvas.height),e.viewport(0,0,e.canvas.width,e.canvas.height),u={},M=null,N={},d={},f=new WeakMap,p=[],m=null,h=!1,g=null,_=null,v=null,y=null,b=null,x=null,S=null,C=new W(0,0,0),w=0,T=!1,E=null,D=null,O=null,k=null,ee=null,ae.set(0,0,e.canvas.width,e.canvas.height),oe.set(0,0,e.canvas.width,e.canvas.height),a.reset(),o.reset(),s.reset()}return{buffers:{color:a,depth:o,stencil:s},enable:le,disable:ue,bindFramebuffer:de,drawBuffers:fe,useProgram:pe,setBlending:ge,setMaterial:_e,setFlipSided:P,setCullFace:ve,setLineWidth:ye,setPolygonOffset:be,setScissorTest:F,activeTexture:xe,bindTexture:I,unbindTexture:L,compressedTexImage2D:Se,compressedTexImage3D:Ce,texImage2D:Ae,texImage3D:je,updateUBOMapping:Pe,uniformBlockBinding:Fe,texStorage2D:Oe,texStorage3D:ke,texSubImage2D:we,texSubImage3D:Te,compressedTexSubImage2D:Ee,compressedTexSubImage3D:De,scissor:Me,viewport:Ne,reset:Ie}}function ms(e,t,n,r){let i=hs(r);switch(n){case w:return e*t;case D:return e*t;case O:return e*t*2;case A:return e*t/i.components*i.byteLength;case te:return e*t/i.components*i.byteLength;case ne:return e*t*2/i.components*i.byteLength;case j:return e*t*2/i.components*i.byteLength;case T:return e*t*3/i.components*i.byteLength;case E:return e*t*4/i.components*i.byteLength;case M:return e*t*4/i.components*i.byteLength;case N:case re:return Math.floor((e+3)/4)*Math.floor((t+3)/4)*8;case ie:case ae:return Math.floor((e+3)/4)*Math.floor((t+3)/4)*16;case se:case le:return Math.max(e,16)*Math.max(t,8)/4;case oe:case ce:return Math.max(e,8)*Math.max(t,8)/2;case ue:case de:return Math.floor((e+3)/4)*Math.floor((t+3)/4)*8;case fe:return Math.floor((e+3)/4)*Math.floor((t+3)/4)*16;case pe:return Math.floor((e+3)/4)*Math.floor((t+3)/4)*16;case me:return Math.floor((e+4)/5)*Math.floor((t+3)/4)*16;case he:return Math.floor((e+4)/5)*Math.floor((t+4)/5)*16;case ge:return Math.floor((e+5)/6)*Math.floor((t+4)/5)*16;case _e:return Math.floor((e+5)/6)*Math.floor((t+5)/6)*16;case P:return Math.floor((e+7)/8)*Math.floor((t+4)/5)*16;case ve:return Math.floor((e+7)/8)*Math.floor((t+5)/6)*16;case ye:return Math.floor((e+7)/8)*Math.floor((t+7)/8)*16;case be:return Math.floor((e+9)/10)*Math.floor((t+4)/5)*16;case F:return Math.floor((e+9)/10)*Math.floor((t+5)/6)*16;case xe:return Math.floor((e+9)/10)*Math.floor((t+7)/8)*16;case I:return Math.floor((e+9)/10)*Math.floor((t+9)/10)*16;case L:return Math.floor((e+11)/12)*Math.floor((t+9)/10)*16;case Se:return Math.floor((e+11)/12)*Math.floor((t+11)/12)*16;case Ce:case we:case Te:return Math.ceil(e/4)*Math.ceil(t/4)*16;case Ee:case De:return Math.ceil(e/4)*Math.ceil(t/4)*8;case Oe:case ke:return Math.ceil(e/4)*Math.ceil(t/4)*16}throw Error(`Unable to determine texture byte length for ${n} format.`)}function hs(e){switch(e){case f:case p:return{byteLength:1,components:1};case h:case m:case y:return{byteLength:2,components:1};case b:case x:return{byteLength:2,components:4};case _:case g:case v:return{byteLength:4,components:1};case C:return{byteLength:4,components:3}}throw Error(`Unknown texture type ${e}.`)}function gs(e,t,n,f,p,m,h){let g=t.has(`WEBGL_multisampled_render_to_texture`)?t.get(`WEBGL_multisampled_render_to_texture`):null,_=typeof navigator>`u`?!1:/OculusBrowser/g.test(navigator.userAgent),v=new R,y=new WeakMap,b,x=new WeakMap,S=!1;try{S=typeof OffscreenCanvas<`u`&&new OffscreenCanvas(1,1).getContext(`2d`)!==null}catch{}function C(e,t){return S?new OffscreenCanvas(e,t):xt(`canvas`)}function w(e,t,n){let r=1,i=Oe(e);if((i.width>n||i.height>n)&&(r=n/Math.max(i.width,i.height)),r<1){if(typeof HTMLImageElement<`u`&&e instanceof HTMLImageElement||typeof HTMLCanvasElement<`u`&&e instanceof HTMLCanvasElement||typeof ImageBitmap<`u`&&e instanceof ImageBitmap||typeof VideoFrame<`u`&&e instanceof VideoFrame){let n=Math.floor(r*i.width),a=Math.floor(r*i.height);b===void 0&&(b=C(n,a));let o=t?C(n,a):b;return o.width=n,o.height=a,o.getContext(`2d`).drawImage(e,0,0,n,a),console.warn(`THREE.WebGLRenderer: Texture has been resized from (`+i.width+`x`+i.height+`) to (`+n+`x`+a+`).`),o}return`data`in e&&console.warn(`THREE.WebGLRenderer: Image in DataTexture is too big (`+i.width+`x`+i.height+`).`),e}return e}function T(e){return e.generateMipmaps}function E(t){e.generateMipmap(t)}function D(t){return t.isWebGLCubeRenderTarget?e.TEXTURE_CUBE_MAP:t.isWebGL3DRenderTarget?e.TEXTURE_3D:t.isWebGLArrayRenderTarget||t.isCompressedArrayTexture?e.TEXTURE_2D_ARRAY:e.TEXTURE_2D}function O(n,r,i,a,o=!1){if(n!==null){if(e[n]!==void 0)return e[n];console.warn(`THREE.WebGLRenderer: Attempt to use non-existing WebGL internal format '`+n+`'`)}let s=r;if(r===e.RED&&(i===e.FLOAT&&(s=e.R32F),i===e.HALF_FLOAT&&(s=e.R16F),i===e.UNSIGNED_BYTE&&(s=e.R8)),r===e.RED_INTEGER&&(i===e.UNSIGNED_BYTE&&(s=e.R8UI),i===e.UNSIGNED_SHORT&&(s=e.R16UI),i===e.UNSIGNED_INT&&(s=e.R32UI),i===e.BYTE&&(s=e.R8I),i===e.SHORT&&(s=e.R16I),i===e.INT&&(s=e.R32I)),r===e.RG&&(i===e.FLOAT&&(s=e.RG32F),i===e.HALF_FLOAT&&(s=e.RG16F),i===e.UNSIGNED_BYTE&&(s=e.RG8)),r===e.RG_INTEGER&&(i===e.UNSIGNED_BYTE&&(s=e.RG8UI),i===e.UNSIGNED_SHORT&&(s=e.RG16UI),i===e.UNSIGNED_INT&&(s=e.RG32UI),i===e.BYTE&&(s=e.RG8I),i===e.SHORT&&(s=e.RG16I),i===e.INT&&(s=e.RG32I)),r===e.RGB_INTEGER&&(i===e.UNSIGNED_BYTE&&(s=e.RGB8UI),i===e.UNSIGNED_SHORT&&(s=e.RGB16UI),i===e.UNSIGNED_INT&&(s=e.RGB32UI),i===e.BYTE&&(s=e.RGB8I),i===e.SHORT&&(s=e.RGB16I),i===e.INT&&(s=e.RGB32I)),r===e.RGBA_INTEGER&&(i===e.UNSIGNED_BYTE&&(s=e.RGBA8UI),i===e.UNSIGNED_SHORT&&(s=e.RGBA16UI),i===e.UNSIGNED_INT&&(s=e.RGBA32UI),i===e.BYTE&&(s=e.RGBA8I),i===e.SHORT&&(s=e.RGBA16I),i===e.INT&&(s=e.RGBA32I)),r===e.RGB&&i===e.UNSIGNED_INT_5_9_9_9_REV&&(s=e.RGB9_E5),r===e.RGBA){let t=o?Be:Ot.getTransfer(a);i===e.FLOAT&&(s=e.RGBA32F),i===e.HALF_FLOAT&&(s=e.RGBA16F),i===e.UNSIGNED_BYTE&&(s=t===`srgb`?e.SRGB8_ALPHA8:e.RGBA8),i===e.UNSIGNED_SHORT_4_4_4_4&&(s=e.RGBA4),i===e.UNSIGNED_SHORT_5_5_5_1&&(s=e.RGB5_A1)}return(s===e.R16F||s===e.R32F||s===e.RG16F||s===e.RG32F||s===e.RGBA16F||s===e.RGBA32F)&&t.get(`EXT_color_buffer_float`),s}function k(t,n){let r;return t?n===null||n===1014||n===1020?r=e.DEPTH24_STENCIL8:n===1015?r=e.DEPTH32F_STENCIL8:n===1012&&(r=e.DEPTH24_STENCIL8,console.warn(`DepthTexture: 16 bit depth attachment is not supported with stencil. Using 24-bit attachment.`)):n===null||n===1014||n===1020?r=e.DEPTH_COMPONENT24:n===1015?r=e.DEPTH_COMPONENT32F:n===1012&&(r=e.DEPTH_COMPONENT16),r}function A(e,t){return T(e)===!0||e.isFramebufferTexture&&e.minFilter!==1003&&e.minFilter!==1006?Math.log2(Math.max(t.width,t.height))+1:e.mipmaps!==void 0&&e.mipmaps.length>0?e.mipmaps.length:e.isCompressedTexture&&Array.isArray(e.image)?t.mipmaps.length:1}function te(e){let t=e.target;t.removeEventListener(`dispose`,te),j(t),t.isVideoTexture&&y.delete(t)}function ne(e){let t=e.target;t.removeEventListener(`dispose`,ne),N(t)}function j(e){let t=f.get(e);if(t.__webglInit===void 0)return;let n=e.source,r=x.get(n);if(r){let i=r[t.__cacheKey];i.usedTimes--,i.usedTimes===0&&M(e),Object.keys(r).length===0&&x.delete(n)}f.remove(e)}function M(t){let n=f.get(t);e.deleteTexture(n.__webglTexture);let r=t.source,i=x.get(r);delete i[n.__cacheKey],h.memory.textures--}function N(t){let n=f.get(t);if(t.depthTexture&&(t.depthTexture.dispose(),f.remove(t.depthTexture)),t.isWebGLCubeRenderTarget)for(let t=0;t<6;t++){if(Array.isArray(n.__webglFramebuffer[t]))for(let r=0;r<n.__webglFramebuffer[t].length;r++)e.deleteFramebuffer(n.__webglFramebuffer[t][r]);else e.deleteFramebuffer(n.__webglFramebuffer[t]);n.__webglDepthbuffer&&e.deleteRenderbuffer(n.__webglDepthbuffer[t])}else{if(Array.isArray(n.__webglFramebuffer))for(let t=0;t<n.__webglFramebuffer.length;t++)e.deleteFramebuffer(n.__webglFramebuffer[t]);else e.deleteFramebuffer(n.__webglFramebuffer);if(n.__webglDepthbuffer&&e.deleteRenderbuffer(n.__webglDepthbuffer),n.__webglMultisampledFramebuffer&&e.deleteFramebuffer(n.__webglMultisampledFramebuffer),n.__webglColorRenderbuffer)for(let t=0;t<n.__webglColorRenderbuffer.length;t++)n.__webglColorRenderbuffer[t]&&e.deleteRenderbuffer(n.__webglColorRenderbuffer[t]);n.__webglDepthRenderbuffer&&e.deleteRenderbuffer(n.__webglDepthRenderbuffer)}let r=t.textures;for(let t=0,n=r.length;t<n;t++){let n=f.get(r[t]);n.__webglTexture&&(e.deleteTexture(n.__webglTexture),h.memory.textures--),f.remove(r[t])}f.remove(t)}let re=0;function ie(){re=0}function ae(){let e=re;return e>=p.maxTextures&&console.warn(`THREE.WebGLTextures: Trying to use `+e+` texture units while this GPU supports only `+p.maxTextures),re+=1,e}function oe(e){let t=[];return t.push(e.wrapS),t.push(e.wrapT),t.push(e.wrapR||0),t.push(e.magFilter),t.push(e.minFilter),t.push(e.anisotropy),t.push(e.internalFormat),t.push(e.format),t.push(e.type),t.push(e.generateMipmaps),t.push(e.premultiplyAlpha),t.push(e.flipY),t.push(e.unpackAlignment),t.push(e.colorSpace),t.join()}function se(t,r){let i=f.get(t);if(t.isVideoTexture&&Ee(t),t.isRenderTargetTexture===!1&&t.version>0&&i.__version!==t.version){let e=t.image;if(e===null)console.warn(`THREE.WebGLRenderer: Texture marked for update but no image data found.`);else if(e.complete===!1)console.warn(`THREE.WebGLRenderer: Texture marked for update but image is incomplete`);else{ge(i,t,r);return}}n.bindTexture(e.TEXTURE_2D,i.__webglTexture,e.TEXTURE0+r)}function ce(t,r){let i=f.get(t);if(t.version>0&&i.__version!==t.version){ge(i,t,r);return}n.bindTexture(e.TEXTURE_2D_ARRAY,i.__webglTexture,e.TEXTURE0+r)}function le(t,r){let i=f.get(t);if(t.version>0&&i.__version!==t.version){ge(i,t,r);return}n.bindTexture(e.TEXTURE_3D,i.__webglTexture,e.TEXTURE0+r)}function ue(t,r){let i=f.get(t);if(t.version>0&&i.__version!==t.version){_e(i,t,r);return}n.bindTexture(e.TEXTURE_CUBE_MAP,i.__webglTexture,e.TEXTURE0+r)}let de={[r]:e.REPEAT,[i]:e.CLAMP_TO_EDGE,[a]:e.MIRRORED_REPEAT},fe={[o]:e.NEAREST,[s]:e.NEAREST_MIPMAP_NEAREST,[c]:e.NEAREST_MIPMAP_LINEAR,[l]:e.LINEAR,[u]:e.LINEAR_MIPMAP_NEAREST,[d]:e.LINEAR_MIPMAP_LINEAR},pe={512:e.NEVER,519:e.ALWAYS,513:e.LESS,515:e.LEQUAL,514:e.EQUAL,518:e.GEQUAL,516:e.GREATER,517:e.NOTEQUAL};function me(n,r){if(r.type===1015&&t.has(`OES_texture_float_linear`)===!1&&(r.magFilter===1006||r.magFilter===1007||r.magFilter===1005||r.magFilter===1008||r.minFilter===1006||r.minFilter===1007||r.minFilter===1005||r.minFilter===1008)&&console.warn(`THREE.WebGLRenderer: Unable to use linear filtering with floating point textures. OES_texture_float_linear not supported on this device.`),e.texParameteri(n,e.TEXTURE_WRAP_S,de[r.wrapS]),e.texParameteri(n,e.TEXTURE_WRAP_T,de[r.wrapT]),(n===e.TEXTURE_3D||n===e.TEXTURE_2D_ARRAY)&&e.texParameteri(n,e.TEXTURE_WRAP_R,de[r.wrapR]),e.texParameteri(n,e.TEXTURE_MAG_FILTER,fe[r.magFilter]),e.texParameteri(n,e.TEXTURE_MIN_FILTER,fe[r.minFilter]),r.compareFunction&&(e.texParameteri(n,e.TEXTURE_COMPARE_MODE,e.COMPARE_REF_TO_TEXTURE),e.texParameteri(n,e.TEXTURE_COMPARE_FUNC,pe[r.compareFunction])),t.has(`EXT_texture_filter_anisotropic`)===!0){if(r.magFilter===1003||r.minFilter!==1005&&r.minFilter!==1008||r.type===1015&&t.has(`OES_texture_float_linear`)===!1)return;if(r.anisotropy>1||f.get(r).__currentAnisotropy){let i=t.get(`EXT_texture_filter_anisotropic`);e.texParameterf(n,i.TEXTURE_MAX_ANISOTROPY_EXT,Math.min(r.anisotropy,p.getMaxAnisotropy())),f.get(r).__currentAnisotropy=r.anisotropy}}}function he(t,n){let r=!1;t.__webglInit===void 0&&(t.__webglInit=!0,n.addEventListener(`dispose`,te));let i=n.source,a=x.get(i);a===void 0&&(a={},x.set(i,a));let o=oe(n);if(o!==t.__cacheKey){a[o]===void 0&&(a[o]={texture:e.createTexture(),usedTimes:0},h.memory.textures++,r=!0),a[o].usedTimes++;let i=a[t.__cacheKey];i!==void 0&&(a[t.__cacheKey].usedTimes--,i.usedTimes===0&&M(n)),t.__cacheKey=o,t.__webglTexture=a[o].texture}return r}function ge(t,r,i){let a=e.TEXTURE_2D;(r.isDataArrayTexture||r.isCompressedArrayTexture)&&(a=e.TEXTURE_2D_ARRAY),r.isData3DTexture&&(a=e.TEXTURE_3D);let o=he(t,r),s=r.source;n.bindTexture(a,t.__webglTexture,e.TEXTURE0+i);let c=f.get(s);if(s.version!==c.__version||o===!0){n.activeTexture(e.TEXTURE0+i);let t=Ot.getPrimaries(Ot.workingColorSpace),l=r.colorSpace===``?null:Ot.getPrimaries(r.colorSpace),u=r.colorSpace===``||t===l?e.NONE:e.BROWSER_DEFAULT_WEBGL;e.pixelStorei(e.UNPACK_FLIP_Y_WEBGL,r.flipY),e.pixelStorei(e.UNPACK_PREMULTIPLY_ALPHA_WEBGL,r.premultiplyAlpha),e.pixelStorei(e.UNPACK_ALIGNMENT,r.unpackAlignment),e.pixelStorei(e.UNPACK_COLORSPACE_CONVERSION_WEBGL,u);let d=w(r.image,!1,p.maxTextureSize);d=De(r,d);let f=m.convert(r.format,r.colorSpace),h=m.convert(r.type),g=O(r.internalFormat,f,h,r.colorSpace,r.isVideoTexture);me(a,r);let _,v=r.mipmaps,y=r.isVideoTexture!==!0,b=c.__version===void 0||o===!0,x=s.dataReady,S=A(r,d);if(r.isDepthTexture)g=k(r.format===ee,r.type),b&&(y?n.texStorage2D(e.TEXTURE_2D,1,g,d.width,d.height):n.texImage2D(e.TEXTURE_2D,0,g,d.width,d.height,0,f,h,null));else if(r.isDataTexture){if(v.length>0){y&&b&&n.texStorage2D(e.TEXTURE_2D,S,g,v[0].width,v[0].height);for(let t=0,r=v.length;t<r;t++)_=v[t],y?x&&n.texSubImage2D(e.TEXTURE_2D,t,0,0,_.width,_.height,f,h,_.data):n.texImage2D(e.TEXTURE_2D,t,g,_.width,_.height,0,f,h,_.data);r.generateMipmaps=!1}else y?(b&&n.texStorage2D(e.TEXTURE_2D,S,g,d.width,d.height),x&&n.texSubImage2D(e.TEXTURE_2D,0,0,0,d.width,d.height,f,h,d.data)):n.texImage2D(e.TEXTURE_2D,0,g,d.width,d.height,0,f,h,d.data)}else if(r.isCompressedTexture){if(r.isCompressedArrayTexture){y&&b&&n.texStorage3D(e.TEXTURE_2D_ARRAY,S,g,v[0].width,v[0].height,d.depth);for(let t=0,i=v.length;t<i;t++)if(_=v[t],r.format!==1023){if(f!==null){if(y){if(x){if(r.layerUpdates.size>0){let i=ms(_.width,_.height,r.format,r.type);for(let a of r.layerUpdates){let r=_.data.subarray(a*i/_.data.BYTES_PER_ELEMENT,(a+1)*i/_.data.BYTES_PER_ELEMENT);n.compressedTexSubImage3D(e.TEXTURE_2D_ARRAY,t,0,0,a,_.width,_.height,1,f,r)}r.clearLayerUpdates()}else n.compressedTexSubImage3D(e.TEXTURE_2D_ARRAY,t,0,0,0,_.width,_.height,d.depth,f,_.data)}}else n.compressedTexImage3D(e.TEXTURE_2D_ARRAY,t,g,_.width,_.height,d.depth,0,_.data,0,0)}else console.warn(`THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()`)}else y?x&&n.texSubImage3D(e.TEXTURE_2D_ARRAY,t,0,0,0,_.width,_.height,d.depth,f,h,_.data):n.texImage3D(e.TEXTURE_2D_ARRAY,t,g,_.width,_.height,d.depth,0,f,h,_.data)}else{y&&b&&n.texStorage2D(e.TEXTURE_2D,S,g,v[0].width,v[0].height);for(let t=0,i=v.length;t<i;t++)_=v[t],r.format===1023?y?x&&n.texSubImage2D(e.TEXTURE_2D,t,0,0,_.width,_.height,f,h,_.data):n.texImage2D(e.TEXTURE_2D,t,g,_.width,_.height,0,f,h,_.data):f===null?console.warn(`THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()`):y?x&&n.compressedTexSubImage2D(e.TEXTURE_2D,t,0,0,_.width,_.height,f,_.data):n.compressedTexImage2D(e.TEXTURE_2D,t,g,_.width,_.height,0,_.data)}}else if(r.isDataArrayTexture){if(y){if(b&&n.texStorage3D(e.TEXTURE_2D_ARRAY,S,g,d.width,d.height,d.depth),x){if(r.layerUpdates.size>0){let t=ms(d.width,d.height,r.format,r.type);for(let i of r.layerUpdates){let r=d.data.subarray(i*t/d.data.BYTES_PER_ELEMENT,(i+1)*t/d.data.BYTES_PER_ELEMENT);n.texSubImage3D(e.TEXTURE_2D_ARRAY,0,0,0,i,d.width,d.height,1,f,h,r)}r.clearLayerUpdates()}else n.texSubImage3D(e.TEXTURE_2D_ARRAY,0,0,0,0,d.width,d.height,d.depth,f,h,d.data)}}else n.texImage3D(e.TEXTURE_2D_ARRAY,0,g,d.width,d.height,d.depth,0,f,h,d.data)}else if(r.isData3DTexture)y?(b&&n.texStorage3D(e.TEXTURE_3D,S,g,d.width,d.height,d.depth),x&&n.texSubImage3D(e.TEXTURE_3D,0,0,0,0,d.width,d.height,d.depth,f,h,d.data)):n.texImage3D(e.TEXTURE_3D,0,g,d.width,d.height,d.depth,0,f,h,d.data);else if(r.isFramebufferTexture){if(b){if(y)n.texStorage2D(e.TEXTURE_2D,S,g,d.width,d.height);else{let t=d.width,r=d.height;for(let i=0;i<S;i++)n.texImage2D(e.TEXTURE_2D,i,g,t,r,0,f,h,null),t>>=1,r>>=1}}}else if(v.length>0){if(y&&b){let t=Oe(v[0]);n.texStorage2D(e.TEXTURE_2D,S,g,t.width,t.height)}for(let t=0,r=v.length;t<r;t++)_=v[t],y?x&&n.texSubImage2D(e.TEXTURE_2D,t,0,0,f,h,_):n.texImage2D(e.TEXTURE_2D,t,g,f,h,_);r.generateMipmaps=!1}else if(y){if(b){let t=Oe(d);n.texStorage2D(e.TEXTURE_2D,S,g,t.width,t.height)}x&&n.texSubImage2D(e.TEXTURE_2D,0,0,0,f,h,d)}else n.texImage2D(e.TEXTURE_2D,0,g,f,h,d);T(r)&&E(a),c.__version=s.version,r.onUpdate&&r.onUpdate(r)}t.__version=r.version}function _e(t,r,i){if(r.image.length!==6)return;let a=he(t,r),o=r.source;n.bindTexture(e.TEXTURE_CUBE_MAP,t.__webglTexture,e.TEXTURE0+i);let s=f.get(o);if(o.version!==s.__version||a===!0){n.activeTexture(e.TEXTURE0+i);let t=Ot.getPrimaries(Ot.workingColorSpace),c=r.colorSpace===``?null:Ot.getPrimaries(r.colorSpace),l=r.colorSpace===``||t===c?e.NONE:e.BROWSER_DEFAULT_WEBGL;e.pixelStorei(e.UNPACK_FLIP_Y_WEBGL,r.flipY),e.pixelStorei(e.UNPACK_PREMULTIPLY_ALPHA_WEBGL,r.premultiplyAlpha),e.pixelStorei(e.UNPACK_ALIGNMENT,r.unpackAlignment),e.pixelStorei(e.UNPACK_COLORSPACE_CONVERSION_WEBGL,l);let u=r.isCompressedTexture||r.image[0].isCompressedTexture,d=r.image[0]&&r.image[0].isDataTexture,f=[];for(let e=0;e<6;e++)!u&&!d?f[e]=w(r.image[e],!0,p.maxCubemapSize):f[e]=d?r.image[e].image:r.image[e],f[e]=De(r,f[e]);let h=f[0],g=m.convert(r.format,r.colorSpace),_=m.convert(r.type),v=O(r.internalFormat,g,_,r.colorSpace),y=r.isVideoTexture!==!0,b=s.__version===void 0||a===!0,x=o.dataReady,S=A(r,h);me(e.TEXTURE_CUBE_MAP,r);let C;if(u){y&&b&&n.texStorage2D(e.TEXTURE_CUBE_MAP,S,v,h.width,h.height);for(let t=0;t<6;t++){C=f[t].mipmaps;for(let i=0;i<C.length;i++){let a=C[i];r.format===1023?y?x&&n.texSubImage2D(e.TEXTURE_CUBE_MAP_POSITIVE_X+t,i,0,0,a.width,a.height,g,_,a.data):n.texImage2D(e.TEXTURE_CUBE_MAP_POSITIVE_X+t,i,v,a.width,a.height,0,g,_,a.data):g===null?console.warn(`THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .setTextureCube()`):y?x&&n.compressedTexSubImage2D(e.TEXTURE_CUBE_MAP_POSITIVE_X+t,i,0,0,a.width,a.height,g,a.data):n.compressedTexImage2D(e.TEXTURE_CUBE_MAP_POSITIVE_X+t,i,v,a.width,a.height,0,a.data)}}}else{if(C=r.mipmaps,y&&b){C.length>0&&S++;let t=Oe(f[0]);n.texStorage2D(e.TEXTURE_CUBE_MAP,S,v,t.width,t.height)}for(let t=0;t<6;t++)if(d){y?x&&n.texSubImage2D(e.TEXTURE_CUBE_MAP_POSITIVE_X+t,0,0,0,f[t].width,f[t].height,g,_,f[t].data):n.texImage2D(e.TEXTURE_CUBE_MAP_POSITIVE_X+t,0,v,f[t].width,f[t].height,0,g,_,f[t].data);for(let r=0;r<C.length;r++){let i=C[r].image[t].image;y?x&&n.texSubImage2D(e.TEXTURE_CUBE_MAP_POSITIVE_X+t,r+1,0,0,i.width,i.height,g,_,i.data):n.texImage2D(e.TEXTURE_CUBE_MAP_POSITIVE_X+t,r+1,v,i.width,i.height,0,g,_,i.data)}}else{y?x&&n.texSubImage2D(e.TEXTURE_CUBE_MAP_POSITIVE_X+t,0,0,0,g,_,f[t]):n.texImage2D(e.TEXTURE_CUBE_MAP_POSITIVE_X+t,0,v,g,_,f[t]);for(let r=0;r<C.length;r++){let i=C[r];y?x&&n.texSubImage2D(e.TEXTURE_CUBE_MAP_POSITIVE_X+t,r+1,0,0,g,_,i.image[t]):n.texImage2D(e.TEXTURE_CUBE_MAP_POSITIVE_X+t,r+1,v,g,_,i.image[t])}}}T(r)&&E(e.TEXTURE_CUBE_MAP),s.__version=o.version,r.onUpdate&&r.onUpdate(r)}t.__version=r.version}function P(t,r,i,a,o,s){let c=m.convert(i.format,i.colorSpace),l=m.convert(i.type),u=O(i.internalFormat,c,l,i.colorSpace),d=f.get(r),p=f.get(i);if(p.__renderTarget=r,!d.__hasExternalTextures){let t=Math.max(1,r.width>>s),i=Math.max(1,r.height>>s);o===e.TEXTURE_3D||o===e.TEXTURE_2D_ARRAY?n.texImage3D(o,s,u,t,i,r.depth,0,c,l,null):n.texImage2D(o,s,u,t,i,0,c,l,null)}n.bindFramebuffer(e.FRAMEBUFFER,t),Te(r)?g.framebufferTexture2DMultisampleEXT(e.FRAMEBUFFER,a,o,p.__webglTexture,0,we(r)):(o===e.TEXTURE_2D||o>=e.TEXTURE_CUBE_MAP_POSITIVE_X&&o<=e.TEXTURE_CUBE_MAP_NEGATIVE_Z)&&e.framebufferTexture2D(e.FRAMEBUFFER,a,o,p.__webglTexture,s),n.bindFramebuffer(e.FRAMEBUFFER,null)}function ve(t,n,r){if(e.bindRenderbuffer(e.RENDERBUFFER,t),n.depthBuffer){let i=n.depthTexture,a=i&&i.isDepthTexture?i.type:null,o=k(n.stencilBuffer,a),s=n.stencilBuffer?e.DEPTH_STENCIL_ATTACHMENT:e.DEPTH_ATTACHMENT,c=we(n);Te(n)?g.renderbufferStorageMultisampleEXT(e.RENDERBUFFER,c,o,n.width,n.height):r?e.renderbufferStorageMultisample(e.RENDERBUFFER,c,o,n.width,n.height):e.renderbufferStorage(e.RENDERBUFFER,o,n.width,n.height),e.framebufferRenderbuffer(e.FRAMEBUFFER,s,e.RENDERBUFFER,t)}else{let t=n.textures;for(let i=0;i<t.length;i++){let a=t[i],o=m.convert(a.format,a.colorSpace),s=m.convert(a.type),c=O(a.internalFormat,o,s,a.colorSpace),l=we(n);r&&Te(n)===!1?e.renderbufferStorageMultisample(e.RENDERBUFFER,l,c,n.width,n.height):Te(n)?g.renderbufferStorageMultisampleEXT(e.RENDERBUFFER,l,c,n.width,n.height):e.renderbufferStorage(e.RENDERBUFFER,c,n.width,n.height)}}e.bindRenderbuffer(e.RENDERBUFFER,null)}function ye(t,r){if(r&&r.isWebGLCubeRenderTarget)throw Error(`Depth Texture with cube render targets is not supported`);if(n.bindFramebuffer(e.FRAMEBUFFER,t),!(r.depthTexture&&r.depthTexture.isDepthTexture))throw Error(`renderTarget.depthTexture must be an instance of THREE.DepthTexture`);let i=f.get(r.depthTexture);i.__renderTarget=r,(!i.__webglTexture||r.depthTexture.image.width!==r.width||r.depthTexture.image.height!==r.height)&&(r.depthTexture.image.width=r.width,r.depthTexture.image.height=r.height,r.depthTexture.needsUpdate=!0),se(r.depthTexture,0);let a=i.__webglTexture,o=we(r);if(r.depthTexture.format===1026)Te(r)?g.framebufferTexture2DMultisampleEXT(e.FRAMEBUFFER,e.DEPTH_ATTACHMENT,e.TEXTURE_2D,a,0,o):e.framebufferTexture2D(e.FRAMEBUFFER,e.DEPTH_ATTACHMENT,e.TEXTURE_2D,a,0);else if(r.depthTexture.format===1027)Te(r)?g.framebufferTexture2DMultisampleEXT(e.FRAMEBUFFER,e.DEPTH_STENCIL_ATTACHMENT,e.TEXTURE_2D,a,0,o):e.framebufferTexture2D(e.FRAMEBUFFER,e.DEPTH_STENCIL_ATTACHMENT,e.TEXTURE_2D,a,0);else throw Error(`Unknown depthTexture format`)}function be(t){let r=f.get(t),i=t.isWebGLCubeRenderTarget===!0;if(r.__boundDepthTexture!==t.depthTexture){let e=t.depthTexture;if(r.__depthDisposeCallback&&r.__depthDisposeCallback(),e){let t=()=>{delete r.__boundDepthTexture,delete r.__depthDisposeCallback,e.removeEventListener(`dispose`,t)};e.addEventListener(`dispose`,t),r.__depthDisposeCallback=t}r.__boundDepthTexture=e}if(t.depthTexture&&!r.__autoAllocateDepthBuffer){if(i)throw Error(`target.depthTexture not supported in Cube render targets`);ye(r.__webglFramebuffer,t)}else if(i){r.__webglDepthbuffer=[];for(let i=0;i<6;i++)if(n.bindFramebuffer(e.FRAMEBUFFER,r.__webglFramebuffer[i]),r.__webglDepthbuffer[i]===void 0)r.__webglDepthbuffer[i]=e.createRenderbuffer(),ve(r.__webglDepthbuffer[i],t,!1);else{let n=t.stencilBuffer?e.DEPTH_STENCIL_ATTACHMENT:e.DEPTH_ATTACHMENT,a=r.__webglDepthbuffer[i];e.bindRenderbuffer(e.RENDERBUFFER,a),e.framebufferRenderbuffer(e.FRAMEBUFFER,n,e.RENDERBUFFER,a)}}else if(n.bindFramebuffer(e.FRAMEBUFFER,r.__webglFramebuffer),r.__webglDepthbuffer===void 0)r.__webglDepthbuffer=e.createRenderbuffer(),ve(r.__webglDepthbuffer,t,!1);else{let n=t.stencilBuffer?e.DEPTH_STENCIL_ATTACHMENT:e.DEPTH_ATTACHMENT,i=r.__webglDepthbuffer;e.bindRenderbuffer(e.RENDERBUFFER,i),e.framebufferRenderbuffer(e.FRAMEBUFFER,n,e.RENDERBUFFER,i)}n.bindFramebuffer(e.FRAMEBUFFER,null)}function F(t,n,r){let i=f.get(t);n!==void 0&&P(i.__webglFramebuffer,t,t.texture,e.COLOR_ATTACHMENT0,e.TEXTURE_2D,0),r!==void 0&&be(t)}function xe(t){let r=t.texture,i=f.get(t),a=f.get(r);t.addEventListener(`dispose`,ne);let o=t.textures,s=t.isWebGLCubeRenderTarget===!0,c=o.length>1;if(c||(a.__webglTexture===void 0&&(a.__webglTexture=e.createTexture()),a.__version=r.version,h.memory.textures++),s){i.__webglFramebuffer=[];for(let t=0;t<6;t++)if(r.mipmaps&&r.mipmaps.length>0){i.__webglFramebuffer[t]=[];for(let n=0;n<r.mipmaps.length;n++)i.__webglFramebuffer[t][n]=e.createFramebuffer()}else i.__webglFramebuffer[t]=e.createFramebuffer()}else{if(r.mipmaps&&r.mipmaps.length>0){i.__webglFramebuffer=[];for(let t=0;t<r.mipmaps.length;t++)i.__webglFramebuffer[t]=e.createFramebuffer()}else i.__webglFramebuffer=e.createFramebuffer();if(c)for(let t=0,n=o.length;t<n;t++){let n=f.get(o[t]);n.__webglTexture===void 0&&(n.__webglTexture=e.createTexture(),h.memory.textures++)}if(t.samples>0&&Te(t)===!1){i.__webglMultisampledFramebuffer=e.createFramebuffer(),i.__webglColorRenderbuffer=[],n.bindFramebuffer(e.FRAMEBUFFER,i.__webglMultisampledFramebuffer);for(let n=0;n<o.length;n++){let r=o[n];i.__webglColorRenderbuffer[n]=e.createRenderbuffer(),e.bindRenderbuffer(e.RENDERBUFFER,i.__webglColorRenderbuffer[n]);let a=m.convert(r.format,r.colorSpace),s=m.convert(r.type),c=O(r.internalFormat,a,s,r.colorSpace,t.isXRRenderTarget===!0),l=we(t);e.renderbufferStorageMultisample(e.RENDERBUFFER,l,c,t.width,t.height),e.framebufferRenderbuffer(e.FRAMEBUFFER,e.COLOR_ATTACHMENT0+n,e.RENDERBUFFER,i.__webglColorRenderbuffer[n])}e.bindRenderbuffer(e.RENDERBUFFER,null),t.depthBuffer&&(i.__webglDepthRenderbuffer=e.createRenderbuffer(),ve(i.__webglDepthRenderbuffer,t,!0)),n.bindFramebuffer(e.FRAMEBUFFER,null)}}if(s){n.bindTexture(e.TEXTURE_CUBE_MAP,a.__webglTexture),me(e.TEXTURE_CUBE_MAP,r);for(let n=0;n<6;n++)if(r.mipmaps&&r.mipmaps.length>0)for(let a=0;a<r.mipmaps.length;a++)P(i.__webglFramebuffer[n][a],t,r,e.COLOR_ATTACHMENT0,e.TEXTURE_CUBE_MAP_POSITIVE_X+n,a);else P(i.__webglFramebuffer[n],t,r,e.COLOR_ATTACHMENT0,e.TEXTURE_CUBE_MAP_POSITIVE_X+n,0);T(r)&&E(e.TEXTURE_CUBE_MAP),n.unbindTexture()}else if(c){for(let r=0,a=o.length;r<a;r++){let a=o[r],s=f.get(a);n.bindTexture(e.TEXTURE_2D,s.__webglTexture),me(e.TEXTURE_2D,a),P(i.__webglFramebuffer,t,a,e.COLOR_ATTACHMENT0+r,e.TEXTURE_2D,0),T(a)&&E(e.TEXTURE_2D)}n.unbindTexture()}else{let o=e.TEXTURE_2D;if((t.isWebGL3DRenderTarget||t.isWebGLArrayRenderTarget)&&(o=t.isWebGL3DRenderTarget?e.TEXTURE_3D:e.TEXTURE_2D_ARRAY),n.bindTexture(o,a.__webglTexture),me(o,r),r.mipmaps&&r.mipmaps.length>0)for(let n=0;n<r.mipmaps.length;n++)P(i.__webglFramebuffer[n],t,r,e.COLOR_ATTACHMENT0,o,n);else P(i.__webglFramebuffer,t,r,e.COLOR_ATTACHMENT0,o,0);T(r)&&E(o),n.unbindTexture()}t.depthBuffer&&be(t)}function I(e){let t=e.textures;for(let r=0,i=t.length;r<i;r++){let i=t[r];if(T(i)){let t=D(e),r=f.get(i).__webglTexture;n.bindTexture(t,r),E(t),n.unbindTexture()}}}let L=[],Se=[];function Ce(t){if(t.samples>0){if(Te(t)===!1){let r=t.textures,i=t.width,a=t.height,o=e.COLOR_BUFFER_BIT,s=t.stencilBuffer?e.DEPTH_STENCIL_ATTACHMENT:e.DEPTH_ATTACHMENT,c=f.get(t),l=r.length>1;if(l)for(let t=0;t<r.length;t++)n.bindFramebuffer(e.FRAMEBUFFER,c.__webglMultisampledFramebuffer),e.framebufferRenderbuffer(e.FRAMEBUFFER,e.COLOR_ATTACHMENT0+t,e.RENDERBUFFER,null),n.bindFramebuffer(e.FRAMEBUFFER,c.__webglFramebuffer),e.framebufferTexture2D(e.DRAW_FRAMEBUFFER,e.COLOR_ATTACHMENT0+t,e.TEXTURE_2D,null,0);n.bindFramebuffer(e.READ_FRAMEBUFFER,c.__webglMultisampledFramebuffer),n.bindFramebuffer(e.DRAW_FRAMEBUFFER,c.__webglFramebuffer);for(let n=0;n<r.length;n++){if(t.resolveDepthBuffer&&(t.depthBuffer&&(o|=e.DEPTH_BUFFER_BIT),t.stencilBuffer&&t.resolveStencilBuffer&&(o|=e.STENCIL_BUFFER_BIT)),l){e.framebufferRenderbuffer(e.READ_FRAMEBUFFER,e.COLOR_ATTACHMENT0,e.RENDERBUFFER,c.__webglColorRenderbuffer[n]);let t=f.get(r[n]).__webglTexture;e.framebufferTexture2D(e.DRAW_FRAMEBUFFER,e.COLOR_ATTACHMENT0,e.TEXTURE_2D,t,0)}e.blitFramebuffer(0,0,i,a,0,0,i,a,o,e.NEAREST),_===!0&&(L.length=0,Se.length=0,L.push(e.COLOR_ATTACHMENT0+n),t.depthBuffer&&t.resolveDepthBuffer===!1&&(L.push(s),Se.push(s),e.invalidateFramebuffer(e.DRAW_FRAMEBUFFER,Se)),e.invalidateFramebuffer(e.READ_FRAMEBUFFER,L))}if(n.bindFramebuffer(e.READ_FRAMEBUFFER,null),n.bindFramebuffer(e.DRAW_FRAMEBUFFER,null),l)for(let t=0;t<r.length;t++){n.bindFramebuffer(e.FRAMEBUFFER,c.__webglMultisampledFramebuffer),e.framebufferRenderbuffer(e.FRAMEBUFFER,e.COLOR_ATTACHMENT0+t,e.RENDERBUFFER,c.__webglColorRenderbuffer[t]);let i=f.get(r[t]).__webglTexture;n.bindFramebuffer(e.FRAMEBUFFER,c.__webglFramebuffer),e.framebufferTexture2D(e.DRAW_FRAMEBUFFER,e.COLOR_ATTACHMENT0+t,e.TEXTURE_2D,i,0)}n.bindFramebuffer(e.DRAW_FRAMEBUFFER,c.__webglMultisampledFramebuffer)}else if(t.depthBuffer&&t.resolveDepthBuffer===!1&&_){let n=t.stencilBuffer?e.DEPTH_STENCIL_ATTACHMENT:e.DEPTH_ATTACHMENT;e.invalidateFramebuffer(e.DRAW_FRAMEBUFFER,[n])}}}function we(e){return Math.min(p.maxSamples,e.samples)}function Te(e){let n=f.get(e);return e.samples>0&&t.has(`WEBGL_multisampled_render_to_texture`)===!0&&n.__useRenderToTexture!==!1}function Ee(e){let t=h.render.frame;y.get(e)!==t&&(y.set(e,t),e.update())}function De(e,t){let n=e.colorSpace,r=e.format,i=e.type;return e.isCompressedTexture===!0||e.isVideoTexture===!0||n!==`srgb-linear`&&n!==``&&(Ot.getTransfer(n)===`srgb`?(r!==1023||i!==1009)&&console.warn(`THREE.WebGLTextures: sRGB encoded textures have to use RGBAFormat and UnsignedByteType.`):console.error(`THREE.WebGLTextures: Unsupported texture color space:`,n)),t}function Oe(e){return typeof HTMLImageElement<`u`&&e instanceof HTMLImageElement?(v.width=e.naturalWidth||e.width,v.height=e.naturalHeight||e.height):typeof VideoFrame<`u`&&e instanceof VideoFrame?(v.width=e.displayWidth,v.height=e.displayHeight):(v.width=e.width,v.height=e.height),v}this.allocateTextureUnit=ae,this.resetTextureUnits=ie,this.setTexture2D=se,this.setTexture2DArray=ce,this.setTexture3D=le,this.setTextureCube=ue,this.rebindTextures=F,this.setupRenderTarget=xe,this.updateRenderTargetMipmap=I,this.updateMultisampleRenderTarget=Ce,this.setupDepthRenderbuffer=be,this.setupFrameBufferTexture=P,this.useMultisampledRTT=Te}function _s(e,t){function n(n,r=``){let i,a=Ot.getTransfer(r);if(n===1009)return e.UNSIGNED_BYTE;if(n===1017)return e.UNSIGNED_SHORT_4_4_4_4;if(n===1018)return e.UNSIGNED_SHORT_5_5_5_1;if(n===35902)return e.UNSIGNED_INT_5_9_9_9_REV;if(n===1010)return e.BYTE;if(n===1011)return e.SHORT;if(n===1012)return e.UNSIGNED_SHORT;if(n===1013)return e.INT;if(n===1014)return e.UNSIGNED_INT;if(n===1015)return e.FLOAT;if(n===1016)return e.HALF_FLOAT;if(n===1021)return e.ALPHA;if(n===1022)return e.RGB;if(n===1023)return e.RGBA;if(n===1024)return e.LUMINANCE;if(n===1025)return e.LUMINANCE_ALPHA;if(n===1026)return e.DEPTH_COMPONENT;if(n===1027)return e.DEPTH_STENCIL;if(n===1028)return e.RED;if(n===1029)return e.RED_INTEGER;if(n===1030)return e.RG;if(n===1031)return e.RG_INTEGER;if(n===1033)return e.RGBA_INTEGER;if(n===33776||n===33777||n===33778||n===33779){if(a===`srgb`){if(i=t.get(`WEBGL_compressed_texture_s3tc_srgb`),i!==null){if(n===33776)return i.COMPRESSED_SRGB_S3TC_DXT1_EXT;if(n===33777)return i.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;if(n===33778)return i.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;if(n===33779)return i.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT}else return null}else if(i=t.get(`WEBGL_compressed_texture_s3tc`),i!==null){if(n===33776)return i.COMPRESSED_RGB_S3TC_DXT1_EXT;if(n===33777)return i.COMPRESSED_RGBA_S3TC_DXT1_EXT;if(n===33778)return i.COMPRESSED_RGBA_S3TC_DXT3_EXT;if(n===33779)return i.COMPRESSED_RGBA_S3TC_DXT5_EXT}else return null}if(n===35840||n===35841||n===35842||n===35843){if(i=t.get(`WEBGL_compressed_texture_pvrtc`),i!==null){if(n===35840)return i.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;if(n===35841)return i.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;if(n===35842)return i.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;if(n===35843)return i.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG}else return null}if(n===36196||n===37492||n===37496){if(i=t.get(`WEBGL_compressed_texture_etc`),i!==null){if(n===36196||n===37492)return a===`srgb`?i.COMPRESSED_SRGB8_ETC2:i.COMPRESSED_RGB8_ETC2;if(n===37496)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC:i.COMPRESSED_RGBA8_ETC2_EAC}else return null}if(n===37808||n===37809||n===37810||n===37811||n===37812||n===37813||n===37814||n===37815||n===37816||n===37817||n===37818||n===37819||n===37820||n===37821){if(i=t.get(`WEBGL_compressed_texture_astc`),i!==null){if(n===37808)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR:i.COMPRESSED_RGBA_ASTC_4x4_KHR;if(n===37809)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR:i.COMPRESSED_RGBA_ASTC_5x4_KHR;if(n===37810)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR:i.COMPRESSED_RGBA_ASTC_5x5_KHR;if(n===37811)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR:i.COMPRESSED_RGBA_ASTC_6x5_KHR;if(n===37812)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR:i.COMPRESSED_RGBA_ASTC_6x6_KHR;if(n===37813)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR:i.COMPRESSED_RGBA_ASTC_8x5_KHR;if(n===37814)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR:i.COMPRESSED_RGBA_ASTC_8x6_KHR;if(n===37815)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR:i.COMPRESSED_RGBA_ASTC_8x8_KHR;if(n===37816)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR:i.COMPRESSED_RGBA_ASTC_10x5_KHR;if(n===37817)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR:i.COMPRESSED_RGBA_ASTC_10x6_KHR;if(n===37818)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR:i.COMPRESSED_RGBA_ASTC_10x8_KHR;if(n===37819)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR:i.COMPRESSED_RGBA_ASTC_10x10_KHR;if(n===37820)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR:i.COMPRESSED_RGBA_ASTC_12x10_KHR;if(n===37821)return a===`srgb`?i.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR:i.COMPRESSED_RGBA_ASTC_12x12_KHR}else return null}if(n===36492||n===36494||n===36495){if(i=t.get(`EXT_texture_compression_bptc`),i!==null){if(n===36492)return a===`srgb`?i.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT:i.COMPRESSED_RGBA_BPTC_UNORM_EXT;if(n===36494)return i.COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT;if(n===36495)return i.COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT}else return null}if(n===36283||n===36284||n===36285||n===36286){if(i=t.get(`EXT_texture_compression_rgtc`),i!==null){if(n===36492)return i.COMPRESSED_RED_RGTC1_EXT;if(n===36284)return i.COMPRESSED_SIGNED_RED_RGTC1_EXT;if(n===36285)return i.COMPRESSED_RED_GREEN_RGTC2_EXT;if(n===36286)return i.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT}else return null}return n===1020?e.UNSIGNED_INT_24_8:e[n]===void 0?null:e[n]}return{convert:n}}var vs=class extends ai{constructor(e=[]){super(),this.isArrayCamera=!0,this.cameras=e}},ys=class extends Yn{constructor(){super(),this.isGroup=!0,this.type=`Group`}},bs={type:`move`},xs=class{constructor(){this._targetRay=null,this._grip=null,this._hand=null}getHandSpace(){return this._hand===null&&(this._hand=new ys,this._hand.matrixAutoUpdate=!1,this._hand.visible=!1,this._hand.joints={},this._hand.inputState={pinching:!1}),this._hand}getTargetRaySpace(){return this._targetRay===null&&(this._targetRay=new ys,this._targetRay.matrixAutoUpdate=!1,this._targetRay.visible=!1,this._targetRay.hasLinearVelocity=!1,this._targetRay.linearVelocity=new H,this._targetRay.hasAngularVelocity=!1,this._targetRay.angularVelocity=new H),this._targetRay}getGripSpace(){return this._grip===null&&(this._grip=new ys,this._grip.matrixAutoUpdate=!1,this._grip.visible=!1,this._grip.hasLinearVelocity=!1,this._grip.linearVelocity=new H,this._grip.hasAngularVelocity=!1,this._grip.angularVelocity=new H),this._grip}dispatchEvent(e){return this._targetRay!==null&&this._targetRay.dispatchEvent(e),this._grip!==null&&this._grip.dispatchEvent(e),this._hand!==null&&this._hand.dispatchEvent(e),this}connect(e){if(e&&e.hand){let t=this._hand;if(t)for(let n of e.hand.values())this._getHandJoint(t,n)}return this.dispatchEvent({type:`connected`,data:e}),this}disconnect(e){return this.dispatchEvent({type:`disconnected`,data:e}),this._targetRay!==null&&(this._targetRay.visible=!1),this._grip!==null&&(this._grip.visible=!1),this._hand!==null&&(this._hand.visible=!1),this}update(e,t,n){let r=null,i=null,a=null,o=this._targetRay,s=this._grip,c=this._hand;if(e&&t.session.visibilityState!==`visible-blurred`){if(c&&e.hand){a=!0;for(let r of e.hand.values()){let e=t.getJointPose(r,n),i=this._getHandJoint(c,r);e!==null&&(i.matrix.fromArray(e.transform.matrix),i.matrix.decompose(i.position,i.rotation,i.scale),i.matrixWorldNeedsUpdate=!0,i.jointRadius=e.radius),i.visible=e!==null}let r=c.joints[`index-finger-tip`],i=c.joints[`thumb-tip`],o=r.position.distanceTo(i.position);c.inputState.pinching&&o>.025?(c.inputState.pinching=!1,this.dispatchEvent({type:`pinchend`,handedness:e.handedness,target:this})):!c.inputState.pinching&&o<=.015&&(c.inputState.pinching=!0,this.dispatchEvent({type:`pinchstart`,handedness:e.handedness,target:this}))}else s!==null&&e.gripSpace&&(i=t.getPose(e.gripSpace,n),i!==null&&(s.matrix.fromArray(i.transform.matrix),s.matrix.decompose(s.position,s.rotation,s.scale),s.matrixWorldNeedsUpdate=!0,i.linearVelocity?(s.hasLinearVelocity=!0,s.linearVelocity.copy(i.linearVelocity)):s.hasLinearVelocity=!1,i.angularVelocity?(s.hasAngularVelocity=!0,s.angularVelocity.copy(i.angularVelocity)):s.hasAngularVelocity=!1));o!==null&&(r=t.getPose(e.targetRaySpace,n),r===null&&i!==null&&(r=i),r!==null&&(o.matrix.fromArray(r.transform.matrix),o.matrix.decompose(o.position,o.rotation,o.scale),o.matrixWorldNeedsUpdate=!0,r.linearVelocity?(o.hasLinearVelocity=!0,o.linearVelocity.copy(r.linearVelocity)):o.hasLinearVelocity=!1,r.angularVelocity?(o.hasAngularVelocity=!0,o.angularVelocity.copy(r.angularVelocity)):o.hasAngularVelocity=!1,this.dispatchEvent(bs)))}return o!==null&&(o.visible=r!==null),s!==null&&(s.visible=i!==null),c!==null&&(c.visible=a!==null),this}_getHandJoint(e,t){if(e.joints[t.jointName]===void 0){let n=new ys;n.matrixAutoUpdate=!1,n.visible=!1,e.joints[t.jointName]=n,e.add(n)}return e.joints[t.jointName]}},Ss=`
void main() {

	gl_Position = vec4( position, 1.0 );

}`,Cs=`
uniform sampler2DArray depthColor;
uniform float depthWidth;
uniform float depthHeight;

void main() {

	vec2 coord = vec2( gl_FragCoord.x / depthWidth, gl_FragCoord.y / depthHeight );

	if ( coord.x >= 1.0 ) {

		gl_FragDepth = texture( depthColor, vec3( coord.x - 1.0, coord.y, 1 ) ).r;

	} else {

		gl_FragDepth = texture( depthColor, vec3( coord.x, coord.y, 0 ) ).r;

	}

}`,ws=class{constructor(){this.texture=null,this.mesh=null,this.depthNear=0,this.depthFar=0}init(e,t,n){if(this.texture===null){let r=new Ht,i=e.properties.get(r);i.__webglTexture=t.texture,(t.depthNear!=n.depthNear||t.depthFar!=n.depthFar)&&(this.depthNear=t.depthNear,this.depthFar=t.depthFar),this.texture=r}}getMesh(e){if(this.texture!==null&&this.mesh===null){let t=e.cameras[0].viewport,n=new ei({vertexShader:Ss,fragmentShader:Cs,uniforms:{depthColor:{value:this.texture},depthWidth:{value:t.z},depthHeight:{value:t.w}}});this.mesh=new Ur(new bi(20,20),n)}return this.mesh}reset(){this.texture=null,this.mesh=null}getDepthTexture(){return this.texture}},Ts=class extends Ge{constructor(e,t){super();let n=this,r=null,i=1,a=null,o=`local-floor`,s=1,c=null,l=null,u=null,d=null,p=null,m=null,h=new ws,g=t.getContextAttributes(),v=null,y=null,b=[],x=[],C=new R,w=null,T=new ai;T.viewport=new B;let D=new ai;D.viewport=new B;let O=[T,D],A=new vs,te=null,ne=null;this.cameraAutoUpdate=!0,this.enabled=!1,this.isPresenting=!1,this.getController=function(e){let t=b[e];return t===void 0&&(t=new xs,b[e]=t),t.getTargetRaySpace()},this.getControllerGrip=function(e){let t=b[e];return t===void 0&&(t=new xs,b[e]=t),t.getGripSpace()},this.getHand=function(e){let t=b[e];return t===void 0&&(t=new xs,b[e]=t),t.getHandSpace()};function j(e){let t=x.indexOf(e.inputSource);if(t===-1)return;let n=b[t];n!==void 0&&(n.update(e.inputSource,e.frame,c||a),n.dispatchEvent({type:e.type,data:e.inputSource}))}function M(){r.removeEventListener(`select`,j),r.removeEventListener(`selectstart`,j),r.removeEventListener(`selectend`,j),r.removeEventListener(`squeeze`,j),r.removeEventListener(`squeezestart`,j),r.removeEventListener(`squeezeend`,j),r.removeEventListener(`end`,M),r.removeEventListener(`inputsourceschange`,N);for(let e=0;e<b.length;e++){let t=x[e];t!==null&&(x[e]=null,b[e].disconnect(t))}te=null,ne=null,h.reset(),e.setRenderTarget(v),p=null,d=null,u=null,r=null,y=null,ue.stop(),n.isPresenting=!1,e.setPixelRatio(w),e.setSize(C.width,C.height,!1),n.dispatchEvent({type:`sessionend`})}this.setFramebufferScaleFactor=function(e){i=e,n.isPresenting===!0&&console.warn(`THREE.WebXRManager: Cannot change framebuffer scale while presenting.`)},this.setReferenceSpaceType=function(e){o=e,n.isPresenting===!0&&console.warn(`THREE.WebXRManager: Cannot change reference space type while presenting.`)},this.getReferenceSpace=function(){return c||a},this.setReferenceSpace=function(e){c=e},this.getBaseLayer=function(){return d===null?p:d},this.getBinding=function(){return u},this.getFrame=function(){return m},this.getSession=function(){return r},this.setSession=async function(l){if(r=l,r!==null){if(v=e.getRenderTarget(),r.addEventListener(`select`,j),r.addEventListener(`selectstart`,j),r.addEventListener(`selectend`,j),r.addEventListener(`squeeze`,j),r.addEventListener(`squeezestart`,j),r.addEventListener(`squeezeend`,j),r.addEventListener(`end`,M),r.addEventListener(`inputsourceschange`,N),g.xrCompatible!==!0&&await t.makeXRCompatible(),w=e.getPixelRatio(),e.getSize(C),r.renderState.layers===void 0){let n={antialias:g.antialias,alpha:!0,depth:g.depth,stencil:g.stencil,framebufferScaleFactor:i};p=new XRWebGLLayer(r,t,n),r.updateRenderState({baseLayer:p}),e.setPixelRatio(1),e.setSize(p.framebufferWidth,p.framebufferHeight,!1),y=new Wt(p.framebufferWidth,p.framebufferHeight,{format:E,type:f,colorSpace:e.outputColorSpace,stencilBuffer:g.stencil})}else{let n=null,a=null,o=null;g.depth&&(o=g.stencil?t.DEPTH24_STENCIL8:t.DEPTH_COMPONENT24,n=g.stencil?ee:k,a=g.stencil?S:_);let s={colorFormat:t.RGBA8,depthFormat:o,scaleFactor:i};u=new XRWebGLBinding(r,t),d=u.createProjectionLayer(s),r.updateRenderState({layers:[d]}),e.setPixelRatio(1),e.setSize(d.textureWidth,d.textureHeight,!1),y=new Wt(d.textureWidth,d.textureHeight,{format:E,type:f,depthTexture:new aa(d.textureWidth,d.textureHeight,a,void 0,void 0,void 0,void 0,void 0,void 0,n),stencilBuffer:g.stencil,colorSpace:e.outputColorSpace,samples:g.antialias?4:0,resolveDepthBuffer:d.ignoreDepthValues===!1})}y.isXRRenderTarget=!0,this.setFoveation(s),c=null,a=await r.requestReferenceSpace(o),ue.setContext(r),ue.start(),n.isPresenting=!0,n.dispatchEvent({type:`sessionstart`})}},this.getEnvironmentBlendMode=function(){if(r!==null)return r.environmentBlendMode},this.getDepthTexture=function(){return h.getDepthTexture()};function N(e){for(let t=0;t<e.removed.length;t++){let n=e.removed[t],r=x.indexOf(n);r>=0&&(x[r]=null,b[r].disconnect(n))}for(let t=0;t<e.added.length;t++){let n=e.added[t],r=x.indexOf(n);if(r===-1){for(let e=0;e<b.length;e++)if(e>=x.length){x.push(n),r=e;break}else if(x[e]===null){x[e]=n,r=e;break}if(r===-1)break}let i=b[r];i&&i.connect(n)}}let re=new H,ie=new H;function ae(e,t,n){re.setFromMatrixPosition(t.matrixWorld),ie.setFromMatrixPosition(n.matrixWorld);let r=re.distanceTo(ie),i=t.projectionMatrix.elements,a=n.projectionMatrix.elements,o=i[14]/(i[10]-1),s=i[14]/(i[10]+1),c=(i[9]+1)/i[5],l=(i[9]-1)/i[5],u=(i[8]-1)/i[0],d=(a[8]+1)/a[0],f=o*u,p=o*d,m=r/(-u+d),h=m*-u;if(t.matrixWorld.decompose(e.position,e.quaternion,e.scale),e.translateX(h),e.translateZ(m),e.matrixWorld.compose(e.position,e.quaternion,e.scale),e.matrixWorldInverse.copy(e.matrixWorld).invert(),i[10]===-1)e.projectionMatrix.copy(t.projectionMatrix),e.projectionMatrixInverse.copy(t.projectionMatrixInverse);else{let t=o+m,n=s+m,i=f-h,a=p+(r-h),u=c*s/n*t,d=l*s/n*t;e.projectionMatrix.makePerspective(i,a,u,d,t,n),e.projectionMatrixInverse.copy(e.projectionMatrix).invert()}}function oe(e,t){t===null?e.matrixWorld.copy(e.matrix):e.matrixWorld.multiplyMatrices(t.matrixWorld,e.matrix),e.matrixWorldInverse.copy(e.matrixWorld).invert()}this.updateCamera=function(e){if(r===null)return;let t=e.near,n=e.far;h.texture!==null&&(h.depthNear>0&&(t=h.depthNear),h.depthFar>0&&(n=h.depthFar)),A.near=D.near=T.near=t,A.far=D.far=T.far=n,(te!==A.near||ne!==A.far)&&(r.updateRenderState({depthNear:A.near,depthFar:A.far}),te=A.near,ne=A.far),T.layers.mask=e.layers.mask|2,D.layers.mask=e.layers.mask|4,A.layers.mask=T.layers.mask|D.layers.mask;let i=e.parent,a=A.cameras;oe(A,i);for(let e=0;e<a.length;e++)oe(a[e],i);a.length===2?ae(A,T,D):A.projectionMatrix.copy(T.projectionMatrix),se(e,A,i)};function se(e,t,n){n===null?e.matrix.copy(t.matrixWorld):(e.matrix.copy(n.matrixWorld),e.matrix.invert(),e.matrix.multiply(t.matrixWorld)),e.matrix.decompose(e.position,e.quaternion,e.scale),e.updateMatrixWorld(!0),e.projectionMatrix.copy(t.projectionMatrix),e.projectionMatrixInverse.copy(t.projectionMatrixInverse),e.isPerspectiveCamera&&(e.fov=Ye*2*Math.atan(1/e.projectionMatrix.elements[5]),e.zoom=1)}this.getCamera=function(){return A},this.getFoveation=function(){if(d!==null||p!==null)return s},this.setFoveation=function(e){s=e,d!==null&&(d.fixedFoveation=e),p!==null&&p.fixedFoveation!==void 0&&(p.fixedFoveation=e)},this.hasDepthSensing=function(){return h.texture!==null},this.getDepthSensingMesh=function(){return h.getMesh(A)};let ce=null;function le(t,i){if(l=i.getViewerPose(c||a),m=i,l!==null){let t=l.views;p!==null&&(e.setRenderTargetFramebuffer(y,p.framebuffer),e.setRenderTarget(y));let n=!1;t.length!==A.cameras.length&&(A.cameras.length=0,n=!0);for(let r=0;r<t.length;r++){let i=t[r],a=null;if(p!==null)a=p.getViewport(i);else{let t=u.getViewSubImage(d,i);a=t.viewport,r===0&&(e.setRenderTargetTextures(y,t.colorTexture,d.ignoreDepthValues?void 0:t.depthStencilTexture),e.setRenderTarget(y))}let o=O[r];o===void 0&&(o=new ai,o.layers.enable(r),o.viewport=new B,O[r]=o),o.matrix.fromArray(i.transform.matrix),o.matrix.decompose(o.position,o.quaternion,o.scale),o.projectionMatrix.fromArray(i.projectionMatrix),o.projectionMatrixInverse.copy(o.projectionMatrix).invert(),o.viewport.set(a.x,a.y,a.width,a.height),r===0&&(A.matrix.copy(o.matrix),A.matrix.decompose(A.position,A.quaternion,A.scale)),n===!0&&A.cameras.push(o)}let i=r.enabledFeatures;if(i&&i.includes(`depth-sensing`)){let n=u.getDepthInformation(t[0]);n&&n.isValid&&n.texture&&h.init(e,n,r.renderState)}}for(let e=0;e<b.length;e++){let t=x[e],n=b[e];t!==null&&n!==void 0&&n.update(t,i,c||a)}ce&&ce(t,i),i.detectedPlanes&&n.dispatchEvent({type:`planesdetected`,data:i}),m=null}let ue=new vi;ue.setAnimationLoop(le),this.setAnimationLoop=function(e){ce=e},this.dispose=function(){}}},Es=new Mn,Ds=new U;function Os(e,t){function n(e,t){e.matrixAutoUpdate===!0&&e.updateMatrix(),t.value.copy(e.matrix)}function r(t,n){n.color.getRGB(t.fogColor.value,Xr(e)),n.isFog?(t.fogNear.value=n.near,t.fogFar.value=n.far):n.isFogExp2&&(t.fogDensity.value=n.density)}function i(e,t,n,r,i){t.isMeshBasicMaterial||t.isMeshLambertMaterial?a(e,t):t.isMeshToonMaterial?(a(e,t),d(e,t)):t.isMeshPhongMaterial?(a(e,t),u(e,t)):t.isMeshStandardMaterial?(a(e,t),f(e,t),t.isMeshPhysicalMaterial&&p(e,t,i)):t.isMeshMatcapMaterial?(a(e,t),m(e,t)):t.isMeshDepthMaterial?a(e,t):t.isMeshDistanceMaterial?(a(e,t),h(e,t)):t.isMeshNormalMaterial?a(e,t):t.isLineBasicMaterial?(o(e,t),t.isLineDashedMaterial&&s(e,t)):t.isPointsMaterial?c(e,t,n,r):t.isSpriteMaterial?l(e,t):t.isShadowMaterial?(e.color.value.copy(t.color),e.opacity.value=t.opacity):t.isShaderMaterial&&(t.uniformsNeedUpdate=!1)}function a(e,r){e.opacity.value=r.opacity,r.color&&e.diffuse.value.copy(r.color),r.emissive&&e.emissive.value.copy(r.emissive).multiplyScalar(r.emissiveIntensity),r.map&&(e.map.value=r.map,n(r.map,e.mapTransform)),r.alphaMap&&(e.alphaMap.value=r.alphaMap,n(r.alphaMap,e.alphaMapTransform)),r.bumpMap&&(e.bumpMap.value=r.bumpMap,n(r.bumpMap,e.bumpMapTransform),e.bumpScale.value=r.bumpScale,r.side===1&&(e.bumpScale.value*=-1)),r.normalMap&&(e.normalMap.value=r.normalMap,n(r.normalMap,e.normalMapTransform),e.normalScale.value.copy(r.normalScale),r.side===1&&e.normalScale.value.negate()),r.displacementMap&&(e.displacementMap.value=r.displacementMap,n(r.displacementMap,e.displacementMapTransform),e.displacementScale.value=r.displacementScale,e.displacementBias.value=r.displacementBias),r.emissiveMap&&(e.emissiveMap.value=r.emissiveMap,n(r.emissiveMap,e.emissiveMapTransform)),r.specularMap&&(e.specularMap.value=r.specularMap,n(r.specularMap,e.specularMapTransform)),r.alphaTest>0&&(e.alphaTest.value=r.alphaTest);let i=t.get(r),a=i.envMap,o=i.envMapRotation;a&&(e.envMap.value=a,Es.copy(o),Es.x*=-1,Es.y*=-1,Es.z*=-1,a.isCubeTexture&&a.isRenderTargetTexture===!1&&(Es.y*=-1,Es.z*=-1),e.envMapRotation.value.setFromMatrix4(Ds.makeRotationFromEuler(Es)),e.flipEnvMap.value=a.isCubeTexture&&a.isRenderTargetTexture===!1?-1:1,e.reflectivity.value=r.reflectivity,e.ior.value=r.ior,e.refractionRatio.value=r.refractionRatio),r.lightMap&&(e.lightMap.value=r.lightMap,e.lightMapIntensity.value=r.lightMapIntensity,n(r.lightMap,e.lightMapTransform)),r.aoMap&&(e.aoMap.value=r.aoMap,e.aoMapIntensity.value=r.aoMapIntensity,n(r.aoMap,e.aoMapTransform))}function o(e,t){e.diffuse.value.copy(t.color),e.opacity.value=t.opacity,t.map&&(e.map.value=t.map,n(t.map,e.mapTransform))}function s(e,t){e.dashSize.value=t.dashSize,e.totalSize.value=t.dashSize+t.gapSize,e.scale.value=t.scale}function c(e,t,r,i){e.diffuse.value.copy(t.color),e.opacity.value=t.opacity,e.size.value=t.size*r,e.scale.value=i*.5,t.map&&(e.map.value=t.map,n(t.map,e.uvTransform)),t.alphaMap&&(e.alphaMap.value=t.alphaMap,n(t.alphaMap,e.alphaMapTransform)),t.alphaTest>0&&(e.alphaTest.value=t.alphaTest)}function l(e,t){e.diffuse.value.copy(t.color),e.opacity.value=t.opacity,e.rotation.value=t.rotation,t.map&&(e.map.value=t.map,n(t.map,e.mapTransform)),t.alphaMap&&(e.alphaMap.value=t.alphaMap,n(t.alphaMap,e.alphaMapTransform)),t.alphaTest>0&&(e.alphaTest.value=t.alphaTest)}function u(e,t){e.specular.value.copy(t.specular),e.shininess.value=Math.max(t.shininess,1e-4)}function d(e,t){t.gradientMap&&(e.gradientMap.value=t.gradientMap)}function f(e,t){e.metalness.value=t.metalness,t.metalnessMap&&(e.metalnessMap.value=t.metalnessMap,n(t.metalnessMap,e.metalnessMapTransform)),e.roughness.value=t.roughness,t.roughnessMap&&(e.roughnessMap.value=t.roughnessMap,n(t.roughnessMap,e.roughnessMapTransform)),t.envMap&&(e.envMapIntensity.value=t.envMapIntensity)}function p(e,t,r){e.ior.value=t.ior,t.sheen>0&&(e.sheenColor.value.copy(t.sheenColor).multiplyScalar(t.sheen),e.sheenRoughness.value=t.sheenRoughness,t.sheenColorMap&&(e.sheenColorMap.value=t.sheenColorMap,n(t.sheenColorMap,e.sheenColorMapTransform)),t.sheenRoughnessMap&&(e.sheenRoughnessMap.value=t.sheenRoughnessMap,n(t.sheenRoughnessMap,e.sheenRoughnessMapTransform))),t.clearcoat>0&&(e.clearcoat.value=t.clearcoat,e.clearcoatRoughness.value=t.clearcoatRoughness,t.clearcoatMap&&(e.clearcoatMap.value=t.clearcoatMap,n(t.clearcoatMap,e.clearcoatMapTransform)),t.clearcoatRoughnessMap&&(e.clearcoatRoughnessMap.value=t.clearcoatRoughnessMap,n(t.clearcoatRoughnessMap,e.clearcoatRoughnessMapTransform)),t.clearcoatNormalMap&&(e.clearcoatNormalMap.value=t.clearcoatNormalMap,n(t.clearcoatNormalMap,e.clearcoatNormalMapTransform),e.clearcoatNormalScale.value.copy(t.clearcoatNormalScale),t.side===1&&e.clearcoatNormalScale.value.negate())),t.dispersion>0&&(e.dispersion.value=t.dispersion),t.iridescence>0&&(e.iridescence.value=t.iridescence,e.iridescenceIOR.value=t.iridescenceIOR,e.iridescenceThicknessMinimum.value=t.iridescenceThicknessRange[0],e.iridescenceThicknessMaximum.value=t.iridescenceThicknessRange[1],t.iridescenceMap&&(e.iridescenceMap.value=t.iridescenceMap,n(t.iridescenceMap,e.iridescenceMapTransform)),t.iridescenceThicknessMap&&(e.iridescenceThicknessMap.value=t.iridescenceThicknessMap,n(t.iridescenceThicknessMap,e.iridescenceThicknessMapTransform))),t.transmission>0&&(e.transmission.value=t.transmission,e.transmissionSamplerMap.value=r.texture,e.transmissionSamplerSize.value.set(r.width,r.height),t.transmissionMap&&(e.transmissionMap.value=t.transmissionMap,n(t.transmissionMap,e.transmissionMapTransform)),e.thickness.value=t.thickness,t.thicknessMap&&(e.thicknessMap.value=t.thicknessMap,n(t.thicknessMap,e.thicknessMapTransform)),e.attenuationDistance.value=t.attenuationDistance,e.attenuationColor.value.copy(t.attenuationColor)),t.anisotropy>0&&(e.anisotropyVector.value.set(t.anisotropy*Math.cos(t.anisotropyRotation),t.anisotropy*Math.sin(t.anisotropyRotation)),t.anisotropyMap&&(e.anisotropyMap.value=t.anisotropyMap,n(t.anisotropyMap,e.anisotropyMapTransform))),e.specularIntensity.value=t.specularIntensity,e.specularColor.value.copy(t.specularColor),t.specularColorMap&&(e.specularColorMap.value=t.specularColorMap,n(t.specularColorMap,e.specularColorMapTransform)),t.specularIntensityMap&&(e.specularIntensityMap.value=t.specularIntensityMap,n(t.specularIntensityMap,e.specularIntensityMapTransform))}function m(e,t){t.matcap&&(e.matcap.value=t.matcap)}function h(e,n){let r=t.get(n).light;e.referencePosition.value.setFromMatrixPosition(r.matrixWorld),e.nearDistance.value=r.shadow.camera.near,e.farDistance.value=r.shadow.camera.far}return{refreshFogUniforms:r,refreshMaterialUniforms:i}}function ks(e,t,n,r){let i={},a={},o=[],s=e.getParameter(e.MAX_UNIFORM_BUFFER_BINDINGS);function c(e,t){let n=t.program;r.uniformBlockBinding(e,n)}function l(e,n){let o=i[e.id];o===void 0&&(m(e),o=u(e),i[e.id]=o,e.addEventListener(`dispose`,g));let s=n.program;r.updateUBOMapping(e,s);let c=t.render.frame;a[e.id]!==c&&(f(e),a[e.id]=c)}function u(t){let n=d();t.__bindingPointIndex=n;let r=e.createBuffer(),i=t.__size,a=t.usage;return e.bindBuffer(e.UNIFORM_BUFFER,r),e.bufferData(e.UNIFORM_BUFFER,i,a),e.bindBuffer(e.UNIFORM_BUFFER,null),e.bindBufferBase(e.UNIFORM_BUFFER,n,r),r}function d(){for(let e=0;e<s;e++)if(o.indexOf(e)===-1)return o.push(e),e;return console.error(`THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached.`),0}function f(t){let n=i[t.id],r=t.uniforms,a=t.__cache;e.bindBuffer(e.UNIFORM_BUFFER,n);for(let t=0,n=r.length;t<n;t++){let n=Array.isArray(r[t])?r[t]:[r[t]];for(let r=0,i=n.length;r<i;r++){let i=n[r];if(p(i,t,r,a)===!0){let t=i.__offset,n=Array.isArray(i.value)?i.value:[i.value],r=0;for(let a=0;a<n.length;a++){let o=n[a],s=h(o);typeof o==`number`||typeof o==`boolean`?(i.__data[0]=o,e.bufferSubData(e.UNIFORM_BUFFER,t+r,i.__data)):o.isMatrix3?(i.__data[0]=o.elements[0],i.__data[1]=o.elements[1],i.__data[2]=o.elements[2],i.__data[3]=0,i.__data[4]=o.elements[3],i.__data[5]=o.elements[4],i.__data[6]=o.elements[5],i.__data[7]=0,i.__data[8]=o.elements[6],i.__data[9]=o.elements[7],i.__data[10]=o.elements[8],i.__data[11]=0):(o.toArray(i.__data,r),r+=s.storage/Float32Array.BYTES_PER_ELEMENT)}e.bufferSubData(e.UNIFORM_BUFFER,t,i.__data)}}}e.bindBuffer(e.UNIFORM_BUFFER,null)}function p(e,t,n,r){let i=e.value,a=t+`_`+n;if(r[a]===void 0)return r[a]=typeof i==`number`||typeof i==`boolean`?i:i.clone(),!0;{let e=r[a];if(typeof i==`number`||typeof i==`boolean`){if(e!==i)return r[a]=i,!0}else if(e.equals(i)===!1)return e.copy(i),!0}return!1}function m(e){let t=e.uniforms,n=0;for(let e=0,r=t.length;e<r;e++){let r=Array.isArray(t[e])?t[e]:[t[e]];for(let e=0,t=r.length;e<t;e++){let t=r[e],i=Array.isArray(t.value)?t.value:[t.value];for(let e=0,r=i.length;e<r;e++){let r=i[e],a=h(r),o=n%16,s=o%a.boundary,c=o+s;n+=s,c!==0&&16-c<a.storage&&(n+=16-c),t.__data=new Float32Array(a.storage/Float32Array.BYTES_PER_ELEMENT),t.__offset=n,n+=a.storage}}}let r=n%16;return r>0&&(n+=16-r),e.__size=n,e.__cache={},this}function h(e){let t={boundary:0,storage:0};return typeof e==`number`||typeof e==`boolean`?(t.boundary=4,t.storage=4):e.isVector2?(t.boundary=8,t.storage=8):e.isVector3||e.isColor?(t.boundary=16,t.storage=12):e.isVector4?(t.boundary=16,t.storage=16):e.isMatrix3?(t.boundary=48,t.storage=48):e.isMatrix4?(t.boundary=64,t.storage=64):e.isTexture?console.warn(`THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.`):console.warn(`THREE.WebGLRenderer: Unsupported uniform value type.`,e),t}function g(t){let n=t.target;n.removeEventListener(`dispose`,g);let r=o.indexOf(n.__bindingPointIndex);o.splice(r,1),e.deleteBuffer(i[n.id]),delete i[n.id],delete a[n.id]}function _(){for(let t in i)e.deleteBuffer(i[t]);o=[],i={},a={}}return{bind:c,update:l,dispose:_}}var As=class{constructor(e={}){let{canvas:t=St(),context:n=null,depth:r=!0,stencil:i=!1,alpha:a=!1,antialias:o=!1,premultipliedAlpha:s=!0,preserveDrawingBuffer:c=!1,powerPreference:l=`default`,failIfMajorPerformanceCaveat:u=!1,reverseDepthBuffer:p=!1}=e;this.isWebGLRenderer=!0;let m;if(n!==null){if(typeof WebGLRenderingContext<`u`&&n instanceof WebGLRenderingContext)throw Error(`THREE.WebGLRenderer: WebGL 1 is not supported since r163.`);m=n.getContextAttributes().alpha}else m=a;let h=new Uint32Array(4),g=new Int32Array(4),_=null,v=null,b=[],x=[];this.domElement=t,this.debug={checkShaderErrors:!0,onShaderError:null},this.autoClear=!0,this.autoClearColor=!0,this.autoClearDepth=!0,this.autoClearStencil=!0,this.sortObjects=!0,this.clippingPlanes=[],this.localClippingEnabled=!1,this._outputColorSpace=Re,this.toneMapping=0,this.toneMappingExposure=1;let S=this,C=!1,w=0,T=0,E=null,D=-1,O=null,k=new B,ee=new B,A=null,te=new W(0),ne=0,j=t.width,M=t.height,N=1,re=null,ie=null,ae=new B(0,0,j,M),oe=new B(0,0,j,M),se=!1,ce=new _i,le=!1,ue=!1,de=new U,fe=new U,pe=new H,me=new B,he={background:null,fog:null,environment:null,overrideMaterial:null,isScene:!0},ge=!1;function _e(){return E===null?N:1}let P=n;function ve(e,n){return t.getContext(e,n)}try{let e={alpha:!0,depth:r,stencil:i,antialias:o,premultipliedAlpha:s,preserveDrawingBuffer:c,powerPreference:l,failIfMajorPerformanceCaveat:u};if(`setAttribute`in t&&t.setAttribute(`data-engine`,`three.js r170`),t.addEventListener(`webglcontextlost`,We,!1),t.addEventListener(`webglcontextrestored`,Ge,!1),t.addEventListener(`webglcontextcreationerror`,Ke,!1),P===null){let t=`webgl2`;if(P=ve(t,e),P===null)throw ve(t)?Error(`Error creating WebGL context with your selected attributes.`):Error(`Error creating WebGL context.`)}}catch(e){throw console.error(`THREE.WebGLRenderer: `+e.message),e}let ye,be,F,xe,I,L,Se,Ce,we,Te,Ee,De,Oe,ke,Ae,je,Me,Ne,Pe,Fe,Ie,Le,Be,Ve;function He(){ye=new $i(P),ye.init(),Le=new _s(P,ye),be=new Oi(P,ye,e,Le),F=new ps(P,ye),be.reverseDepthBuffer&&p&&F.buffers.depth.setReversed(!0),xe=new na(P),I=new Yo,L=new gs(P,ye,F,I,be,Le,xe),Se=new Ai(S),Ce=new Qi(S),we=new yi(P),Be=new Ei(P,we),Te=new ea(P,we,xe,Be),Ee=new ia(P,Te,we,xe),Pe=new ra(P,be,L),je=new ki(I),De=new Jo(S,Se,Ce,ye,be,Be,je),Oe=new Os(S,I),ke=new $o,Ae=new os(ye),Ne=new Ti(S,Se,Ce,F,Ee,m,s),Me=new ds(S,Ee,be),Ve=new ks(P,xe,be,F),Fe=new Di(P,ye,xe),Ie=new ta(P,ye,xe),xe.programs=De.programs,S.capabilities=be,S.extensions=ye,S.properties=I,S.renderLists=ke,S.shadowMap=Me,S.state=F,S.info=xe}He();let Ue=new Ts(S,P);this.xr=Ue,this.getContext=function(){return P},this.getContextAttributes=function(){return P.getContextAttributes()},this.forceContextLoss=function(){let e=ye.get(`WEBGL_lose_context`);e&&e.loseContext()},this.forceContextRestore=function(){let e=ye.get(`WEBGL_lose_context`);e&&e.restoreContext()},this.getPixelRatio=function(){return N},this.setPixelRatio=function(e){e!==void 0&&(N=e,this.setSize(j,M,!1))},this.getSize=function(e){return e.set(j,M)},this.setSize=function(e,n,r=!0){if(Ue.isPresenting){console.warn(`THREE.WebGLRenderer: Can't change size while VR device is presenting.`);return}j=e,M=n,t.width=Math.floor(e*N),t.height=Math.floor(n*N),r===!0&&(t.style.width=e+`px`,t.style.height=n+`px`),this.setViewport(0,0,e,n)},this.getDrawingBufferSize=function(e){return e.set(j*N,M*N).floor()},this.setDrawingBufferSize=function(e,n,r){j=e,M=n,N=r,t.width=Math.floor(e*r),t.height=Math.floor(n*r),this.setViewport(0,0,e,n)},this.getCurrentViewport=function(e){return e.copy(k)},this.getViewport=function(e){return e.copy(ae)},this.setViewport=function(e,t,n,r){e.isVector4?ae.set(e.x,e.y,e.z,e.w):ae.set(e,t,n,r),F.viewport(k.copy(ae).multiplyScalar(N).round())},this.getScissor=function(e){return e.copy(oe)},this.setScissor=function(e,t,n,r){e.isVector4?oe.set(e.x,e.y,e.z,e.w):oe.set(e,t,n,r),F.scissor(ee.copy(oe).multiplyScalar(N).round())},this.getScissorTest=function(){return se},this.setScissorTest=function(e){F.setScissorTest(se=e)},this.setOpaqueSort=function(e){re=e},this.setTransparentSort=function(e){ie=e},this.getClearColor=function(e){return e.copy(Ne.getClearColor())},this.setClearColor=function(){Ne.setClearColor.apply(Ne,arguments)},this.getClearAlpha=function(){return Ne.getClearAlpha()},this.setClearAlpha=function(){Ne.setClearAlpha.apply(Ne,arguments)},this.clear=function(e=!0,t=!0,n=!0){let r=0;if(e){let e=!1;if(E!==null){let t=E.texture.format;e=t===1033||t===1031||t===1029}if(e){let e=E.texture.type,t=e===1009||e===1014||e===1012||e===1020||e===1017||e===1018,n=Ne.getClearColor(),r=Ne.getClearAlpha(),i=n.r,a=n.g,o=n.b;t?(h[0]=i,h[1]=a,h[2]=o,h[3]=r,P.clearBufferuiv(P.COLOR,0,h)):(g[0]=i,g[1]=a,g[2]=o,g[3]=r,P.clearBufferiv(P.COLOR,0,g))}else r|=P.COLOR_BUFFER_BIT}t&&(r|=P.DEPTH_BUFFER_BIT),n&&(r|=P.STENCIL_BUFFER_BIT,this.state.buffers.stencil.setMask(4294967295)),P.clear(r)},this.clearColor=function(){this.clear(!0,!1,!1)},this.clearDepth=function(){this.clear(!1,!0,!1)},this.clearStencil=function(){this.clear(!1,!1,!0)},this.dispose=function(){t.removeEventListener(`webglcontextlost`,We,!1),t.removeEventListener(`webglcontextrestored`,Ge,!1),t.removeEventListener(`webglcontextcreationerror`,Ke,!1),ke.dispose(),Ae.dispose(),I.dispose(),Se.dispose(),Ce.dispose(),Ee.dispose(),Be.dispose(),Ve.dispose(),De.dispose(),Ue.dispose(),Ue.removeEventListener(`sessionstart`,$e),Ue.removeEventListener(`sessionend`,et),tt.stop()};function We(e){e.preventDefault(),console.log(`THREE.WebGLRenderer: Context Lost.`),C=!0}function Ge(){console.log(`THREE.WebGLRenderer: Context Restored.`),C=!1;let e=xe.autoReset,t=Me.enabled,n=Me.autoUpdate,r=Me.needsUpdate,i=Me.type;He(),xe.autoReset=e,Me.enabled=t,Me.autoUpdate=n,Me.needsUpdate=r,Me.type=i}function Ke(e){console.error(`THREE.WebGLRenderer: A WebGL context could not be created. Reason: `,e.statusMessage)}function qe(e){let t=e.target;t.removeEventListener(`dispose`,qe),Je(t)}function Je(e){Ye(e),I.remove(e)}function Ye(e){let t=I.get(e).programs;t!==void 0&&(t.forEach(function(e){De.releaseProgram(e)}),e.isShaderMaterial&&De.releaseShaderCache(e))}this.renderBufferDirect=function(e,t,n,r,i,a){t===null&&(t=he);let o=i.isMesh&&i.matrixWorld.determinant()<0,s=ut(e,t,n,r,i);F.setMaterial(r,o);let c=n.index,l=1;if(r.wireframe===!0){if(c=Te.getWireframeAttribute(n),c===void 0)return;l=2}let u=n.drawRange,d=n.attributes.position,f=u.start*l,p=(u.start+u.count)*l;a!==null&&(f=Math.max(f,a.start*l),p=Math.min(p,(a.start+a.count)*l)),c===null?d!=null&&(f=Math.max(f,0),p=Math.min(p,d.count)):(f=Math.max(f,0),p=Math.min(p,c.count));let m=p-f;if(m<0||m===1/0)return;Be.setup(i,r,s,n,c);let h,g=Fe;if(c!==null&&(h=we.get(c),g=Ie,g.setIndex(h)),i.isMesh)r.wireframe===!0?(F.setLineWidth(r.wireframeLinewidth*_e()),g.setMode(P.LINES)):g.setMode(P.TRIANGLES);else if(i.isLine){let e=r.linewidth;e===void 0&&(e=1),F.setLineWidth(e*_e()),i.isLineSegments?g.setMode(P.LINES):i.isLineLoop?g.setMode(P.LINE_LOOP):g.setMode(P.LINE_STRIP)}else i.isPoints?g.setMode(P.POINTS):i.isSprite&&g.setMode(P.TRIANGLES);if(i.isBatchedMesh){if(i._multiDrawInstances!==null)g.renderMultiDrawInstances(i._multiDrawStarts,i._multiDrawCounts,i._multiDrawCount,i._multiDrawInstances);else if(ye.get(`WEBGL_multi_draw`))g.renderMultiDraw(i._multiDrawStarts,i._multiDrawCounts,i._multiDrawCount);else{let e=i._multiDrawStarts,t=i._multiDrawCounts,n=i._multiDrawCount,a=c?we.get(c).bytesPerElement:1,o=I.get(r).currentProgram.getUniforms();for(let r=0;r<n;r++)o.setValue(P,`_gl_DrawID`,r),g.render(e[r]/a,t[r])}}else if(i.isInstancedMesh)g.renderInstances(f,m,i.count);else if(n.isInstancedBufferGeometry){let e=n._maxInstanceCount===void 0?1/0:n._maxInstanceCount,t=Math.min(n.instanceCount,e);g.renderInstances(f,m,t)}else g.render(f,m)};function Xe(e,t,n){e.transparent===!0&&e.side===2&&e.forceSinglePass===!1?(e.side=1,e.needsUpdate=!0,st(e,t,n),e.side=0,e.needsUpdate=!0,st(e,t,n),e.side=2):st(e,t,n)}this.compile=function(e,t,n=null){n===null&&(n=e),v=Ae.get(n),v.init(t),x.push(v),n.traverseVisible(function(e){e.isLight&&e.layers.test(t.layers)&&(v.pushLight(e),e.castShadow&&v.pushShadow(e))}),e!==n&&e.traverseVisible(function(e){e.isLight&&e.layers.test(t.layers)&&(v.pushLight(e),e.castShadow&&v.pushShadow(e))}),v.setupLights();let r=new Set;return e.traverse(function(e){if(!(e.isMesh||e.isPoints||e.isLine||e.isSprite))return;let t=e.material;if(t){if(Array.isArray(t))for(let i=0;i<t.length;i++){let a=t[i];Xe(a,n,e),r.add(a)}else Xe(t,n,e),r.add(t)}}),x.pop(),v=null,r},this.compileAsync=function(e,t,n=null){let r=this.compile(e,t,n);return new Promise(t=>{function n(){if(r.forEach(function(e){I.get(e).currentProgram.isReady()&&r.delete(e)}),r.size===0){t(e);return}setTimeout(n,10)}ye.get(`KHR_parallel_shader_compile`)===null?setTimeout(n,10):n()})};let Ze=null;function Qe(e){Ze&&Ze(e)}function $e(){tt.stop()}function et(){tt.start()}let tt=new vi;tt.setAnimationLoop(Qe),typeof self<`u`&&tt.setContext(self),this.setAnimationLoop=function(e){Ze=e,Ue.setAnimationLoop(e),e===null?tt.stop():tt.start()},Ue.addEventListener(`sessionstart`,$e),Ue.addEventListener(`sessionend`,et),this.render=function(e,t){if(t!==void 0&&t.isCamera!==!0){console.error(`THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.`);return}if(C===!0)return;if(e.matrixWorldAutoUpdate===!0&&e.updateMatrixWorld(),t.parent===null&&t.matrixWorldAutoUpdate===!0&&t.updateMatrixWorld(),Ue.enabled===!0&&Ue.isPresenting===!0&&(Ue.cameraAutoUpdate===!0&&Ue.updateCamera(t),t=Ue.getCamera()),e.isScene===!0&&e.onBeforeRender(S,e,t,E),v=Ae.get(e,x.length),v.init(t),x.push(v),fe.multiplyMatrices(t.projectionMatrix,t.matrixWorldInverse),ce.setFromProjectionMatrix(fe),ue=this.localClippingEnabled,le=je.init(this.clippingPlanes,ue),_=ke.get(e,b.length),_.init(),b.push(_),Ue.enabled===!0&&Ue.isPresenting===!0){let e=S.xr.getDepthSensingMesh();e!==null&&nt(e,t,-1/0,S.sortObjects)}nt(e,t,0,S.sortObjects),_.finish(),S.sortObjects===!0&&_.sort(re,ie),ge=Ue.enabled===!1||Ue.isPresenting===!1||Ue.hasDepthSensing()===!1,ge&&Ne.addToRenderList(_,e),this.info.render.frame++,le===!0&&je.beginShadows();let n=v.state.shadowsArray;Me.render(n,e,t),le===!0&&je.endShadows(),this.info.autoReset===!0&&this.info.reset();let r=_.opaque,i=_.transmissive;if(v.setupLights(),t.isArrayCamera){let n=t.cameras;if(i.length>0)for(let t=0,a=n.length;t<a;t++){let a=n[t];it(r,i,e,a)}ge&&Ne.render(e);for(let t=0,r=n.length;t<r;t++){let r=n[t];rt(_,e,r,r.viewport)}}else i.length>0&&it(r,i,e,t),ge&&Ne.render(e),rt(_,e,t);E!==null&&(L.updateMultisampleRenderTarget(E),L.updateRenderTargetMipmap(E)),e.isScene===!0&&e.onAfterRender(S,e,t),Be.resetDefaultState(),D=-1,O=null,x.pop(),x.length>0?(v=x[x.length-1],le===!0&&je.setGlobalState(S.clippingPlanes,v.state.camera)):v=null,b.pop(),_=b.length>0?b[b.length-1]:null};function nt(e,t,n,r){if(e.visible===!1)return;if(e.layers.test(t.layers)){if(e.isGroup)n=e.renderOrder;else if(e.isLOD)e.autoUpdate===!0&&e.update(t);else if(e.isLight)v.pushLight(e),e.castShadow&&v.pushShadow(e);else if(e.isSprite){if(!e.frustumCulled||ce.intersectsSprite(e)){r&&me.setFromMatrixPosition(e.matrixWorld).applyMatrix4(fe);let t=Ee.update(e),i=e.material;i.visible&&_.push(e,t,i,n,me.z,null)}}else if((e.isMesh||e.isLine||e.isPoints)&&(!e.frustumCulled||ce.intersectsObject(e))){let t=Ee.update(e),i=e.material;if(r&&(e.boundingSphere===void 0?(t.boundingSphere===null&&t.computeBoundingSphere(),me.copy(t.boundingSphere.center)):(e.boundingSphere===null&&e.computeBoundingSphere(),me.copy(e.boundingSphere.center)),me.applyMatrix4(e.matrixWorld).applyMatrix4(fe)),Array.isArray(i)){let r=t.groups;for(let a=0,o=r.length;a<o;a++){let o=r[a],s=i[o.materialIndex];s&&s.visible&&_.push(e,t,s,n,me.z,o)}}else i.visible&&_.push(e,t,i,n,me.z,null)}}let i=e.children;for(let e=0,a=i.length;e<a;e++)nt(i[e],t,n,r)}function rt(e,t,n,r){let i=e.opaque,a=e.transmissive,o=e.transparent;v.setupLightsView(n),le===!0&&je.setGlobalState(S.clippingPlanes,n),r&&F.viewport(k.copy(r)),i.length>0&&at(i,t,n),a.length>0&&at(a,t,n),o.length>0&&at(o,t,n),F.buffers.depth.setTest(!0),F.buffers.depth.setMask(!0),F.buffers.color.setMask(!0),F.setPolygonOffset(!1)}function it(e,t,n,r){if((n.isScene===!0?n.overrideMaterial:null)!==null)return;v.state.transmissionRenderTarget[r.id]===void 0&&(v.state.transmissionRenderTarget[r.id]=new Wt(1,1,{generateMipmaps:!0,type:ye.has(`EXT_color_buffer_half_float`)||ye.has(`EXT_color_buffer_float`)?y:f,minFilter:d,samples:4,stencilBuffer:i,resolveDepthBuffer:!1,resolveStencilBuffer:!1,colorSpace:Ot.workingColorSpace}));let a=v.state.transmissionRenderTarget[r.id],o=r.viewport||k;a.setSize(o.z,o.w);let s=S.getRenderTarget();S.setRenderTarget(a),S.getClearColor(te),ne=S.getClearAlpha(),ne<1&&S.setClearColor(16777215,.5),S.clear(),ge&&Ne.render(n);let c=S.toneMapping;S.toneMapping=0;let l=r.viewport;if(r.viewport!==void 0&&(r.viewport=void 0),v.setupLightsView(r),le===!0&&je.setGlobalState(S.clippingPlanes,r),at(e,n,r),L.updateMultisampleRenderTarget(a),L.updateRenderTargetMipmap(a),ye.has(`WEBGL_multisampled_render_to_texture`)===!1){let e=!1;for(let i=0,a=t.length;i<a;i++){let a=t[i],o=a.object,s=a.geometry,c=a.material,l=a.group;if(c.side===2&&o.layers.test(r.layers)){let t=c.side;c.side=1,c.needsUpdate=!0,ot(o,n,r,s,c,l),c.side=t,c.needsUpdate=!0,e=!0}}e===!0&&(L.updateMultisampleRenderTarget(a),L.updateRenderTargetMipmap(a))}S.setRenderTarget(s),S.setClearColor(te,ne),l!==void 0&&(r.viewport=l),S.toneMapping=c}function at(e,t,n){let r=t.isScene===!0?t.overrideMaterial:null;for(let i=0,a=e.length;i<a;i++){let a=e[i],o=a.object,s=a.geometry,c=r===null?a.material:r,l=a.group;o.layers.test(n.layers)&&ot(o,t,n,s,c,l)}}function ot(e,t,n,r,i,a){e.onBeforeRender(S,t,n,r,i,a),e.modelViewMatrix.multiplyMatrices(n.matrixWorldInverse,e.matrixWorld),e.normalMatrix.getNormalMatrix(e.modelViewMatrix),i.onBeforeRender(S,t,n,r,e,a),i.transparent===!0&&i.side===2&&i.forceSinglePass===!1?(i.side=1,i.needsUpdate=!0,S.renderBufferDirect(n,t,r,i,e,a),i.side=0,i.needsUpdate=!0,S.renderBufferDirect(n,t,r,i,e,a),i.side=2):S.renderBufferDirect(n,t,r,i,e,a),e.onAfterRender(S,t,n,r,i,a)}function st(e,t,n){t.isScene!==!0&&(t=he);let r=I.get(e),i=v.state.lights,a=v.state.shadowsArray,o=i.state.version,s=De.getParameters(e,i.state,a,t,n),c=De.getProgramCacheKey(s),l=r.programs;r.environment=e.isMeshStandardMaterial?t.environment:null,r.fog=t.fog,r.envMap=(e.isMeshStandardMaterial?Ce:Se).get(e.envMap||r.environment),r.envMapRotation=r.environment!==null&&e.envMap===null?t.environmentRotation:e.envMapRotation,l===void 0&&(e.addEventListener(`dispose`,qe),l=new Map,r.programs=l);let u=l.get(c);if(u!==void 0){if(r.currentProgram===u&&r.lightsStateVersion===o)return lt(e,s),u}else s.uniforms=De.getUniforms(e),e.onBeforeCompile(s,S),u=De.acquireProgram(s,c),l.set(c,u),r.uniforms=s.uniforms;let d=r.uniforms;return(!e.isShaderMaterial&&!e.isRawShaderMaterial||e.clipping===!0)&&(d.clippingPlanes=je.uniform),lt(e,s),r.needsLights=ft(e),r.lightsStateVersion=o,r.needsLights&&(d.ambientLightColor.value=i.state.ambient,d.lightProbe.value=i.state.probe,d.directionalLights.value=i.state.directional,d.directionalLightShadows.value=i.state.directionalShadow,d.spotLights.value=i.state.spot,d.spotLightShadows.value=i.state.spotShadow,d.rectAreaLights.value=i.state.rectArea,d.ltc_1.value=i.state.rectAreaLTC1,d.ltc_2.value=i.state.rectAreaLTC2,d.pointLights.value=i.state.point,d.pointLightShadows.value=i.state.pointShadow,d.hemisphereLights.value=i.state.hemi,d.directionalShadowMap.value=i.state.directionalShadowMap,d.directionalShadowMatrix.value=i.state.directionalShadowMatrix,d.spotShadowMap.value=i.state.spotShadowMap,d.spotLightMatrix.value=i.state.spotLightMatrix,d.spotLightMap.value=i.state.spotLightMap,d.pointShadowMap.value=i.state.pointShadowMap,d.pointShadowMatrix.value=i.state.pointShadowMatrix),r.currentProgram=u,r.uniformsList=null,u}function ct(e){if(e.uniformsList===null){let t=e.currentProgram.getUniforms();e.uniformsList=po.seqWithValue(t.seq,e.uniforms)}return e.uniformsList}function lt(e,t){let n=I.get(e);n.outputColorSpace=t.outputColorSpace,n.batching=t.batching,n.batchingColor=t.batchingColor,n.instancing=t.instancing,n.instancingColor=t.instancingColor,n.instancingMorph=t.instancingMorph,n.skinning=t.skinning,n.morphTargets=t.morphTargets,n.morphNormals=t.morphNormals,n.morphColors=t.morphColors,n.morphTargetsCount=t.morphTargetsCount,n.numClippingPlanes=t.numClippingPlanes,n.numIntersection=t.numClipIntersection,n.vertexAlphas=t.vertexAlphas,n.vertexTangents=t.vertexTangents,n.toneMapping=t.toneMapping}function ut(e,t,n,r,i){t.isScene!==!0&&(t=he),L.resetTextureUnits();let a=t.fog,o=r.isMeshStandardMaterial?t.environment:null,s=E===null?S.outputColorSpace:E.isXRRenderTarget===!0?E.texture.colorSpace:ze,c=(r.isMeshStandardMaterial?Ce:Se).get(r.envMap||o),l=r.vertexColors===!0&&!!n.attributes.color&&n.attributes.color.itemSize===4,u=!!n.attributes.tangent&&(!!r.normalMap||r.anisotropy>0),d=!!n.morphAttributes.position,f=!!n.morphAttributes.normal,p=!!n.morphAttributes.color,m=0;r.toneMapped&&(E===null||E.isXRRenderTarget===!0)&&(m=S.toneMapping);let h=n.morphAttributes.position||n.morphAttributes.normal||n.morphAttributes.color,g=h===void 0?0:h.length,_=I.get(r),y=v.state.lights;if(le===!0&&(ue===!0||e!==O)){let t=e===O&&r.id===D;je.setState(r,e,t)}let b=!1;r.version===_.__version?_.needsLights&&_.lightsStateVersion!==y.state.version?b=!0:_.outputColorSpace===s?i.isBatchedMesh&&_.batching===!1||!i.isBatchedMesh&&_.batching===!0||i.isBatchedMesh&&_.batchingColor===!0&&i.colorTexture===null||i.isBatchedMesh&&_.batchingColor===!1&&i.colorTexture!==null||i.isInstancedMesh&&_.instancing===!1||!i.isInstancedMesh&&_.instancing===!0||i.isSkinnedMesh&&_.skinning===!1||!i.isSkinnedMesh&&_.skinning===!0||i.isInstancedMesh&&_.instancingColor===!0&&i.instanceColor===null||i.isInstancedMesh&&_.instancingColor===!1&&i.instanceColor!==null||i.isInstancedMesh&&_.instancingMorph===!0&&i.morphTexture===null||i.isInstancedMesh&&_.instancingMorph===!1&&i.morphTexture!==null?b=!0:_.envMap===c?r.fog===!0&&_.fog!==a||_.numClippingPlanes!==void 0&&(_.numClippingPlanes!==je.numPlanes||_.numIntersection!==je.numIntersection)?b=!0:_.vertexAlphas===l&&_.vertexTangents===u&&_.morphTargets===d&&_.morphNormals===f&&_.morphColors===p&&_.toneMapping===m?_.morphTargetsCount!==g&&(b=!0):b=!0:b=!0:b=!0:(b=!0,_.__version=r.version);let x=_.currentProgram;b===!0&&(x=st(r,t,i));let C=!1,w=!1,T=!1,k=x.getUniforms(),ee=_.uniforms;if(F.useProgram(x.program)&&(C=!0,w=!0,T=!0),r.id!==D&&(D=r.id,w=!0),C||O!==e){F.buffers.depth.getReversed()?(de.copy(e.projectionMatrix),Et(de),Dt(de),k.setValue(P,`projectionMatrix`,de)):k.setValue(P,`projectionMatrix`,e.projectionMatrix),k.setValue(P,`viewMatrix`,e.matrixWorldInverse);let t=k.map.cameraPosition;t!==void 0&&t.setValue(P,pe.setFromMatrixPosition(e.matrixWorld)),be.logarithmicDepthBuffer&&k.setValue(P,`logDepthBufFC`,2/(Math.log(e.far+1)/Math.LN2)),(r.isMeshPhongMaterial||r.isMeshToonMaterial||r.isMeshLambertMaterial||r.isMeshBasicMaterial||r.isMeshStandardMaterial||r.isShaderMaterial)&&k.setValue(P,`isOrthographic`,e.isOrthographicCamera===!0),O!==e&&(O=e,w=!0,T=!0)}if(i.isSkinnedMesh){k.setOptional(P,i,`bindMatrix`),k.setOptional(P,i,`bindMatrixInverse`);let e=i.skeleton;e&&(e.boneTexture===null&&e.computeBoneTexture(),k.setValue(P,`boneTexture`,e.boneTexture,L))}i.isBatchedMesh&&(k.setOptional(P,i,`batchingTexture`),k.setValue(P,`batchingTexture`,i._matricesTexture,L),k.setOptional(P,i,`batchingIdTexture`),k.setValue(P,`batchingIdTexture`,i._indirectTexture,L),k.setOptional(P,i,`batchingColorTexture`),i._colorsTexture!==null&&k.setValue(P,`batchingColorTexture`,i._colorsTexture,L));let A=n.morphAttributes;if((A.position!==void 0||A.normal!==void 0||A.color!==void 0)&&Pe.update(i,n,x),(w||_.receiveShadow!==i.receiveShadow)&&(_.receiveShadow=i.receiveShadow,k.setValue(P,`receiveShadow`,i.receiveShadow)),r.isMeshGouraudMaterial&&r.envMap!==null&&(ee.envMap.value=c,ee.flipEnvMap.value=c.isCubeTexture&&c.isRenderTargetTexture===!1?-1:1),r.isMeshStandardMaterial&&r.envMap===null&&t.environment!==null&&(ee.envMapIntensity.value=t.environmentIntensity),w&&(k.setValue(P,`toneMappingExposure`,S.toneMappingExposure),_.needsLights&&dt(ee,T),a&&r.fog===!0&&Oe.refreshFogUniforms(ee,a),Oe.refreshMaterialUniforms(ee,r,N,M,v.state.transmissionRenderTarget[e.id]),po.upload(P,ct(_),ee,L)),r.isShaderMaterial&&r.uniformsNeedUpdate===!0&&(po.upload(P,ct(_),ee,L),r.uniformsNeedUpdate=!1),r.isSpriteMaterial&&k.setValue(P,`center`,i.center),k.setValue(P,`modelViewMatrix`,i.modelViewMatrix),k.setValue(P,`normalMatrix`,i.normalMatrix),k.setValue(P,`modelMatrix`,i.matrixWorld),r.isShaderMaterial||r.isRawShaderMaterial){let e=r.uniformsGroups;for(let t=0,n=e.length;t<n;t++){let n=e[t];Ve.update(n,x),Ve.bind(n,x)}}return x}function dt(e,t){e.ambientLightColor.needsUpdate=t,e.lightProbe.needsUpdate=t,e.directionalLights.needsUpdate=t,e.directionalLightShadows.needsUpdate=t,e.pointLights.needsUpdate=t,e.pointLightShadows.needsUpdate=t,e.spotLights.needsUpdate=t,e.spotLightShadows.needsUpdate=t,e.rectAreaLights.needsUpdate=t,e.hemisphereLights.needsUpdate=t}function ft(e){return e.isMeshLambertMaterial||e.isMeshToonMaterial||e.isMeshPhongMaterial||e.isMeshStandardMaterial||e.isShadowMaterial||e.isShaderMaterial&&e.lights===!0}this.getActiveCubeFace=function(){return w},this.getActiveMipmapLevel=function(){return T},this.getRenderTarget=function(){return E},this.setRenderTargetTextures=function(e,t,n){I.get(e.texture).__webglTexture=t,I.get(e.depthTexture).__webglTexture=n;let r=I.get(e);r.__hasExternalTextures=!0,r.__autoAllocateDepthBuffer=n===void 0,r.__autoAllocateDepthBuffer||ye.has(`WEBGL_multisampled_render_to_texture`)===!0&&(console.warn(`THREE.WebGLRenderer: Render-to-texture extension was disabled because an external texture was provided`),r.__useRenderToTexture=!1)},this.setRenderTargetFramebuffer=function(e,t){let n=I.get(e);n.__webglFramebuffer=t,n.__useDefaultFramebuffer=t===void 0},this.setRenderTarget=function(e,t=0,n=0){E=e,w=t,T=n;let r=!0,i=null,a=!1,o=!1;if(e){let s=I.get(e);if(s.__useDefaultFramebuffer!==void 0)F.bindFramebuffer(P.FRAMEBUFFER,null),r=!1;else if(s.__webglFramebuffer===void 0)L.setupRenderTarget(e);else if(s.__hasExternalTextures)L.rebindTextures(e,I.get(e.texture).__webglTexture,I.get(e.depthTexture).__webglTexture);else if(e.depthBuffer){let t=e.depthTexture;if(s.__boundDepthTexture!==t){if(t!==null&&I.has(t)&&(e.width!==t.image.width||e.height!==t.image.height))throw Error(`WebGLRenderTarget: Attached DepthTexture is initialized to the incorrect size.`);L.setupDepthRenderbuffer(e)}}let c=e.texture;(c.isData3DTexture||c.isDataArrayTexture||c.isCompressedArrayTexture)&&(o=!0);let l=I.get(e).__webglFramebuffer;e.isWebGLCubeRenderTarget?(i=Array.isArray(l[t])?l[t][n]:l[t],a=!0):i=e.samples>0&&L.useMultisampledRTT(e)===!1?I.get(e).__webglMultisampledFramebuffer:Array.isArray(l)?l[n]:l,k.copy(e.viewport),ee.copy(e.scissor),A=e.scissorTest}else k.copy(ae).multiplyScalar(N).floor(),ee.copy(oe).multiplyScalar(N).floor(),A=se;if(F.bindFramebuffer(P.FRAMEBUFFER,i)&&r&&F.drawBuffers(e,i),F.viewport(k),F.scissor(ee),F.setScissorTest(A),a){let r=I.get(e.texture);P.framebufferTexture2D(P.FRAMEBUFFER,P.COLOR_ATTACHMENT0,P.TEXTURE_CUBE_MAP_POSITIVE_X+t,r.__webglTexture,n)}else if(o){let r=I.get(e.texture),i=t||0;P.framebufferTextureLayer(P.FRAMEBUFFER,P.COLOR_ATTACHMENT0,r.__webglTexture,n||0,i)}D=-1},this.readRenderTargetPixels=function(e,t,n,r,i,a,o){if(!(e&&e.isWebGLRenderTarget)){console.error(`THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.`);return}let s=I.get(e).__webglFramebuffer;if(e.isWebGLCubeRenderTarget&&o!==void 0&&(s=s[o]),s){F.bindFramebuffer(P.FRAMEBUFFER,s);try{let o=e.texture,s=o.format,c=o.type;if(!be.textureFormatReadable(s)){console.error(`THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in RGBA or implementation defined format.`);return}if(!be.textureTypeReadable(c)){console.error(`THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in UnsignedByteType or implementation defined type.`);return}t>=0&&t<=e.width-r&&n>=0&&n<=e.height-i&&P.readPixels(t,n,r,i,Le.convert(s),Le.convert(c),a)}finally{let e=E===null?null:I.get(E).__webglFramebuffer;F.bindFramebuffer(P.FRAMEBUFFER,e)}}},this.readRenderTargetPixelsAsync=async function(e,t,n,r,i,a,o){if(!(e&&e.isWebGLRenderTarget))throw Error(`THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.`);let s=I.get(e).__webglFramebuffer;if(e.isWebGLCubeRenderTarget&&o!==void 0&&(s=s[o]),s){let o=e.texture,c=o.format,l=o.type;if(!be.textureFormatReadable(c))throw Error(`THREE.WebGLRenderer.readRenderTargetPixelsAsync: renderTarget is not in RGBA or implementation defined format.`);if(!be.textureTypeReadable(l))throw Error(`THREE.WebGLRenderer.readRenderTargetPixelsAsync: renderTarget is not in UnsignedByteType or implementation defined type.`);if(t>=0&&t<=e.width-r&&n>=0&&n<=e.height-i){F.bindFramebuffer(P.FRAMEBUFFER,s);let e=P.createBuffer();P.bindBuffer(P.PIXEL_PACK_BUFFER,e),P.bufferData(P.PIXEL_PACK_BUFFER,a.byteLength,P.STREAM_READ),P.readPixels(t,n,r,i,Le.convert(c),Le.convert(l),0);let o=E===null?null:I.get(E).__webglFramebuffer;F.bindFramebuffer(P.FRAMEBUFFER,o);let u=P.fenceSync(P.SYNC_GPU_COMMANDS_COMPLETE,0);return P.flush(),await Tt(P,u,4),P.bindBuffer(P.PIXEL_PACK_BUFFER,e),P.getBufferSubData(P.PIXEL_PACK_BUFFER,0,a),P.deleteBuffer(e),P.deleteSync(u),a}throw Error(`THREE.WebGLRenderer.readRenderTargetPixelsAsync: requested read bounds are out of range.`)}},this.copyFramebufferToTexture=function(e,t=null,n=0){e.isTexture!==!0&&(wt(`WebGLRenderer: copyFramebufferToTexture function signature has changed.`),t=arguments[0]||null,e=arguments[1]);let r=2**-n,i=Math.floor(e.image.width*r),a=Math.floor(e.image.height*r),o=t===null?0:t.x,s=t===null?0:t.y;L.setTexture2D(e,0),P.copyTexSubImage2D(P.TEXTURE_2D,n,0,0,o,s,i,a),F.unbindTexture()},this.copyTextureToTexture=function(e,t,n=null,r=null,i=0){e.isTexture!==!0&&(wt(`WebGLRenderer: copyTextureToTexture function signature has changed.`),r=arguments[0]||null,e=arguments[1],t=arguments[2],i=arguments[3]||0,n=null);let a,o,s,c,l,u,d,f,p,m=e.isCompressedTexture?e.mipmaps[i]:e.image;n===null?(a=m.width,o=m.height,s=m.depth||1,c=0,l=0,u=0):(a=n.max.x-n.min.x,o=n.max.y-n.min.y,s=n.isBox3?n.max.z-n.min.z:1,c=n.min.x,l=n.min.y,u=n.isBox3?n.min.z:0),r===null?(d=0,f=0,p=0):(d=r.x,f=r.y,p=r.z);let h=Le.convert(t.format),g=Le.convert(t.type),_;t.isData3DTexture?(L.setTexture3D(t,0),_=P.TEXTURE_3D):t.isDataArrayTexture||t.isCompressedArrayTexture?(L.setTexture2DArray(t,0),_=P.TEXTURE_2D_ARRAY):(L.setTexture2D(t,0),_=P.TEXTURE_2D),P.pixelStorei(P.UNPACK_FLIP_Y_WEBGL,t.flipY),P.pixelStorei(P.UNPACK_PREMULTIPLY_ALPHA_WEBGL,t.premultiplyAlpha),P.pixelStorei(P.UNPACK_ALIGNMENT,t.unpackAlignment);let v=P.getParameter(P.UNPACK_ROW_LENGTH),y=P.getParameter(P.UNPACK_IMAGE_HEIGHT),b=P.getParameter(P.UNPACK_SKIP_PIXELS),x=P.getParameter(P.UNPACK_SKIP_ROWS),S=P.getParameter(P.UNPACK_SKIP_IMAGES);P.pixelStorei(P.UNPACK_ROW_LENGTH,m.width),P.pixelStorei(P.UNPACK_IMAGE_HEIGHT,m.height),P.pixelStorei(P.UNPACK_SKIP_PIXELS,c),P.pixelStorei(P.UNPACK_SKIP_ROWS,l),P.pixelStorei(P.UNPACK_SKIP_IMAGES,u);let C=e.isDataArrayTexture||e.isData3DTexture,w=t.isDataArrayTexture||t.isData3DTexture;if(e.isRenderTargetTexture||e.isDepthTexture){let n=I.get(e),r=I.get(t),m=I.get(n.__renderTarget),h=I.get(r.__renderTarget);F.bindFramebuffer(P.READ_FRAMEBUFFER,m.__webglFramebuffer),F.bindFramebuffer(P.DRAW_FRAMEBUFFER,h.__webglFramebuffer);for(let n=0;n<s;n++)C&&P.framebufferTextureLayer(P.READ_FRAMEBUFFER,P.COLOR_ATTACHMENT0,I.get(e).__webglTexture,i,u+n),e.isDepthTexture?(w&&P.framebufferTextureLayer(P.DRAW_FRAMEBUFFER,P.COLOR_ATTACHMENT0,I.get(t).__webglTexture,i,p+n),P.blitFramebuffer(c,l,a,o,d,f,a,o,P.DEPTH_BUFFER_BIT,P.NEAREST)):w?P.copyTexSubImage3D(_,i,d,f,p+n,c,l,a,o):P.copyTexSubImage2D(_,i,d,f,p+n,c,l,a,o);F.bindFramebuffer(P.READ_FRAMEBUFFER,null),F.bindFramebuffer(P.DRAW_FRAMEBUFFER,null)}else w?e.isDataTexture||e.isData3DTexture?P.texSubImage3D(_,i,d,f,p,a,o,s,h,g,m.data):t.isCompressedArrayTexture?P.compressedTexSubImage3D(_,i,d,f,p,a,o,s,h,m.data):P.texSubImage3D(_,i,d,f,p,a,o,s,h,g,m):e.isDataTexture?P.texSubImage2D(P.TEXTURE_2D,i,d,f,a,o,h,g,m.data):e.isCompressedTexture?P.compressedTexSubImage2D(P.TEXTURE_2D,i,d,f,m.width,m.height,h,m.data):P.texSubImage2D(P.TEXTURE_2D,i,d,f,a,o,h,g,m);P.pixelStorei(P.UNPACK_ROW_LENGTH,v),P.pixelStorei(P.UNPACK_IMAGE_HEIGHT,y),P.pixelStorei(P.UNPACK_SKIP_PIXELS,b),P.pixelStorei(P.UNPACK_SKIP_ROWS,x),P.pixelStorei(P.UNPACK_SKIP_IMAGES,S),i===0&&t.generateMipmaps&&P.generateMipmap(_),F.unbindTexture()},this.copyTextureToTexture3D=function(e,t,n=null,r=null,i=0){return e.isTexture!==!0&&(wt(`WebGLRenderer: copyTextureToTexture3D function signature has changed.`),n=arguments[0]||null,r=arguments[1]||null,e=arguments[2],t=arguments[3],i=arguments[4]||0),wt(`WebGLRenderer: copyTextureToTexture3D function has been deprecated. Use "copyTextureToTexture" instead.`),this.copyTextureToTexture(e,t,n,r,i)},this.initRenderTarget=function(e){I.get(e).__webglFramebuffer===void 0&&L.setupRenderTarget(e)},this.initTexture=function(e){e.isCubeTexture?L.setTextureCube(e,0):e.isData3DTexture?L.setTexture3D(e,0):e.isDataArrayTexture||e.isCompressedArrayTexture?L.setTexture2DArray(e,0):L.setTexture2D(e,0),F.unbindTexture()},this.resetState=function(){w=0,T=0,E=null,F.reset(),Be.reset()},typeof __THREE_DEVTOOLS__<`u`&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent(`observe`,{detail:this}))}get coordinateSystem(){return We}get outputColorSpace(){return this._outputColorSpace}set outputColorSpace(e){this._outputColorSpace=e;let t=this.getContext();t.drawingBufferColorspace=Ot._getDrawingBufferColorSpace(e),t.unpackColorSpace=Ot._getUnpackColorSpace()}},js=class extends Yn{constructor(){super(),this.isScene=!0,this.type=`Scene`,this.background=null,this.environment=null,this.fog=null,this.backgroundBlurriness=0,this.backgroundIntensity=1,this.backgroundRotation=new Mn,this.environmentIntensity=1,this.environmentRotation=new Mn,this.overrideMaterial=null,typeof __THREE_DEVTOOLS__<`u`&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent(`observe`,{detail:this}))}copy(e,t){return super.copy(e,t),e.background!==null&&(this.background=e.background.clone()),e.environment!==null&&(this.environment=e.environment.clone()),e.fog!==null&&(this.fog=e.fog.clone()),this.backgroundBlurriness=e.backgroundBlurriness,this.backgroundIntensity=e.backgroundIntensity,this.backgroundRotation.copy(e.backgroundRotation),this.environmentIntensity=e.environmentIntensity,this.environmentRotation.copy(e.environmentRotation),e.overrideMaterial!==null&&(this.overrideMaterial=e.overrideMaterial.clone()),this.matrixAutoUpdate=e.matrixAutoUpdate,this}toJSON(e){let t=super.toJSON(e);return this.fog!==null&&(t.object.fog=this.fog.toJSON()),this.backgroundBlurriness>0&&(t.object.backgroundBlurriness=this.backgroundBlurriness),this.backgroundIntensity!==1&&(t.object.backgroundIntensity=this.backgroundIntensity),t.object.backgroundRotation=this.backgroundRotation.toArray(),this.environmentIntensity!==1&&(t.object.environmentIntensity=this.environmentIntensity),t.object.environmentRotation=this.environmentRotation.toArray(),t}},Ms=class{constructor(e,t){this.isInterleavedBuffer=!0,this.array=e,this.stride=t,this.count=e===void 0?0:e.length/t,this.usage=Ue,this.updateRanges=[],this.version=0,this.uuid=Xe()}onUploadCallback(){}set needsUpdate(e){e===!0&&this.version++}setUsage(e){return this.usage=e,this}addUpdateRange(e,t){this.updateRanges.push({start:e,count:t})}clearUpdateRanges(){this.updateRanges.length=0}copy(e){return this.array=new e.array.constructor(e.array),this.count=e.count,this.stride=e.stride,this.usage=e.usage,this}copyAt(e,t,n){e*=this.stride,n*=t.stride;for(let r=0,i=this.stride;r<i;r++)this.array[e+r]=t.array[n+r];return this}set(e,t=0){return this.array.set(e,t),this}clone(e){e.arrayBuffers===void 0&&(e.arrayBuffers={}),this.array.buffer._uuid===void 0&&(this.array.buffer._uuid=Xe()),e.arrayBuffers[this.array.buffer._uuid]===void 0&&(e.arrayBuffers[this.array.buffer._uuid]=this.array.slice(0).buffer);let t=new this.array.constructor(e.arrayBuffers[this.array.buffer._uuid]),n=new this.constructor(t,this.stride);return n.setUsage(this.usage),n}onUpload(e){return this.onUploadCallback=e,this}toJSON(e){return e.arrayBuffers===void 0&&(e.arrayBuffers={}),this.array.buffer._uuid===void 0&&(this.array.buffer._uuid=Xe()),e.arrayBuffers[this.array.buffer._uuid]===void 0&&(e.arrayBuffers[this.array.buffer._uuid]=Array.from(new Uint32Array(this.array.buffer))),{uuid:this.uuid,buffer:this.array.buffer._uuid,type:this.array.constructor.name,stride:this.stride}}},Ns=new H,Ps=class e{constructor(e,t,n,r=!1){this.isInterleavedBufferAttribute=!0,this.name=``,this.data=e,this.itemSize=t,this.offset=n,this.normalized=r}get count(){return this.data.count}get array(){return this.data.array}set needsUpdate(e){this.data.needsUpdate=e}applyMatrix4(e){for(let t=0,n=this.data.count;t<n;t++)Ns.fromBufferAttribute(this,t),Ns.applyMatrix4(e),this.setXYZ(t,Ns.x,Ns.y,Ns.z);return this}applyNormalMatrix(e){for(let t=0,n=this.count;t<n;t++)Ns.fromBufferAttribute(this,t),Ns.applyNormalMatrix(e),this.setXYZ(t,Ns.x,Ns.y,Ns.z);return this}transformDirection(e){for(let t=0,n=this.count;t<n;t++)Ns.fromBufferAttribute(this,t),Ns.transformDirection(e),this.setXYZ(t,Ns.x,Ns.y,Ns.z);return this}getComponent(e,t){let n=this.array[e*this.data.stride+this.offset+t];return this.normalized&&(n=gt(n,this.array)),n}setComponent(e,t,n){return this.normalized&&(n=_t(n,this.array)),this.data.array[e*this.data.stride+this.offset+t]=n,this}setX(e,t){return this.normalized&&(t=_t(t,this.array)),this.data.array[e*this.data.stride+this.offset]=t,this}setY(e,t){return this.normalized&&(t=_t(t,this.array)),this.data.array[e*this.data.stride+this.offset+1]=t,this}setZ(e,t){return this.normalized&&(t=_t(t,this.array)),this.data.array[e*this.data.stride+this.offset+2]=t,this}setW(e,t){return this.normalized&&(t=_t(t,this.array)),this.data.array[e*this.data.stride+this.offset+3]=t,this}getX(e){let t=this.data.array[e*this.data.stride+this.offset];return this.normalized&&(t=gt(t,this.array)),t}getY(e){let t=this.data.array[e*this.data.stride+this.offset+1];return this.normalized&&(t=gt(t,this.array)),t}getZ(e){let t=this.data.array[e*this.data.stride+this.offset+2];return this.normalized&&(t=gt(t,this.array)),t}getW(e){let t=this.data.array[e*this.data.stride+this.offset+3];return this.normalized&&(t=gt(t,this.array)),t}setXY(e,t,n){return e=e*this.data.stride+this.offset,this.normalized&&(t=_t(t,this.array),n=_t(n,this.array)),this.data.array[e+0]=t,this.data.array[e+1]=n,this}setXYZ(e,t,n,r){return e=e*this.data.stride+this.offset,this.normalized&&(t=_t(t,this.array),n=_t(n,this.array),r=_t(r,this.array)),this.data.array[e+0]=t,this.data.array[e+1]=n,this.data.array[e+2]=r,this}setXYZW(e,t,n,r,i){return e=e*this.data.stride+this.offset,this.normalized&&(t=_t(t,this.array),n=_t(n,this.array),r=_t(r,this.array),i=_t(i,this.array)),this.data.array[e+0]=t,this.data.array[e+1]=n,this.data.array[e+2]=r,this.data.array[e+3]=i,this}clone(t){if(t===void 0){console.log(`THREE.InterleavedBufferAttribute.clone(): Cloning an interleaved buffer attribute will de-interleave buffer data.`);let e=[];for(let t=0;t<this.count;t++){let n=t*this.data.stride+this.offset;for(let t=0;t<this.itemSize;t++)e.push(this.data.array[n+t])}return new br(new this.array.constructor(e),this.itemSize,this.normalized)}return t.interleavedBuffers===void 0&&(t.interleavedBuffers={}),t.interleavedBuffers[this.data.uuid]===void 0&&(t.interleavedBuffers[this.data.uuid]=this.data.clone(t)),new e(t.interleavedBuffers[this.data.uuid],this.itemSize,this.offset,this.normalized)}toJSON(e){if(e===void 0){console.log(`THREE.InterleavedBufferAttribute.toJSON(): Serializing an interleaved buffer attribute will de-interleave buffer data.`);let e=[];for(let t=0;t<this.count;t++){let n=t*this.data.stride+this.offset;for(let t=0;t<this.itemSize;t++)e.push(this.data.array[n+t])}return{itemSize:this.itemSize,type:this.array.constructor.name,array:e,normalized:this.normalized}}return e.interleavedBuffers===void 0&&(e.interleavedBuffers={}),e.interleavedBuffers[this.data.uuid]===void 0&&(e.interleavedBuffers[this.data.uuid]=this.data.toJSON(e)),{isInterleavedBufferAttribute:!0,itemSize:this.itemSize,data:this.data.uuid,offset:this.offset,normalized:this.normalized}}},Fs=class extends gr{static get type(){return`SpriteMaterial`}constructor(e){super(),this.isSpriteMaterial=!0,this.color=new W(16777215),this.map=null,this.alphaMap=null,this.rotation=0,this.sizeAttenuation=!0,this.transparent=!0,this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.alphaMap=e.alphaMap,this.rotation=e.rotation,this.sizeAttenuation=e.sizeAttenuation,this.fog=e.fog,this}},Is,Ls=new H,Rs=new H,zs=new H,Bs=new R,Vs=new R,Hs=new U,Us=new H,Ws=new H,Gs=new H,Ks=new R,qs=new R,Js=new R,Ys=class extends Yn{constructor(e=new Fs){if(super(),this.isSprite=!0,this.type=`Sprite`,Is===void 0){Is=new jr;let e=new Ms(new Float32Array([-.5,-.5,0,0,0,.5,-.5,0,1,0,.5,.5,0,1,1,-.5,.5,0,0,1]),5);Is.setIndex([0,1,2,0,2,3]),Is.setAttribute(`position`,new Ps(e,3,0,!1)),Is.setAttribute(`uv`,new Ps(e,2,3,!1))}this.geometry=Is,this.material=e,this.center=new R(.5,.5)}raycast(e,t){e.camera===null&&console.error(`THREE.Sprite: "Raycaster.camera" needs to be set in order to raycast against sprites.`),Rs.setFromMatrixScale(this.matrixWorld),Hs.copy(e.camera.matrixWorld),this.modelViewMatrix.multiplyMatrices(e.camera.matrixWorldInverse,this.matrixWorld),zs.setFromMatrixPosition(this.modelViewMatrix),e.camera.isPerspectiveCamera&&this.material.sizeAttenuation===!1&&Rs.multiplyScalar(-zs.z);let n=this.material.rotation,r,i;n!==0&&(i=Math.cos(n),r=Math.sin(n));let a=this.center;Xs(Us.set(-.5,-.5,0),zs,a,Rs,r,i),Xs(Ws.set(.5,-.5,0),zs,a,Rs,r,i),Xs(Gs.set(.5,.5,0),zs,a,Rs,r,i),Ks.set(0,0),qs.set(1,0),Js.set(1,1);let o=e.ray.intersectTriangle(Us,Ws,Gs,!1,Ls);if(o===null&&(Xs(Ws.set(-.5,.5,0),zs,a,Rs,r,i),qs.set(0,1),o=e.ray.intersectTriangle(Us,Gs,Ws,!1,Ls),o===null))return;let s=e.ray.origin.distanceTo(Ls);s<e.near||s>e.far||t.push({distance:s,point:Ls.clone(),uv:lr.getInterpolation(Ls,Us,Ws,Gs,Ks,qs,Js,new R),face:null,object:this})}copy(e,t){return super.copy(e,t),e.center!==void 0&&this.center.copy(e.center),this.material=e.material,this}};function Xs(e,t,n,r,i,a){Bs.subVectors(e,n).addScalar(.5).multiply(r),i===void 0?Vs.copy(Bs):(Vs.x=a*Bs.x-i*Bs.y,Vs.y=i*Bs.x+a*Bs.y),e.copy(t),e.x+=Vs.x,e.y+=Vs.y,e.applyMatrix4(Hs)}var Zs=class extends Ht{constructor(e=null,t=1,n=1,r,i,a,s,c,l=o,u=o,d,f){super(null,a,s,c,l,u,r,i,d,f),this.isDataTexture=!0,this.image={data:e,width:t,height:n},this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1}},Qs=class extends br{constructor(e,t,n,r=1){super(e,t,n),this.isInstancedBufferAttribute=!0,this.meshPerAttribute=r}copy(e){return super.copy(e),this.meshPerAttribute=e.meshPerAttribute,this}toJSON(){let e=super.toJSON();return e.meshPerAttribute=this.meshPerAttribute,e.isInstancedBufferAttribute=!0,e}},$s=new U,ec=new U,tc=[],nc=new Yt,rc=new U,ic=new Ur,ac=new mn,oc=class extends Ur{constructor(e,t,n){super(e,t),this.isInstancedMesh=!0,this.instanceMatrix=new Qs(new Float32Array(n*16),16),this.instanceColor=null,this.morphTexture=null,this.count=n,this.boundingBox=null,this.boundingSphere=null;for(let e=0;e<n;e++)this.setMatrixAt(e,rc)}computeBoundingBox(){let e=this.geometry,t=this.count;this.boundingBox===null&&(this.boundingBox=new Yt),e.boundingBox===null&&e.computeBoundingBox(),this.boundingBox.makeEmpty();for(let n=0;n<t;n++)this.getMatrixAt(n,$s),nc.copy(e.boundingBox).applyMatrix4($s),this.boundingBox.union(nc)}computeBoundingSphere(){let e=this.geometry,t=this.count;this.boundingSphere===null&&(this.boundingSphere=new mn),e.boundingSphere===null&&e.computeBoundingSphere(),this.boundingSphere.makeEmpty();for(let n=0;n<t;n++)this.getMatrixAt(n,$s),ac.copy(e.boundingSphere).applyMatrix4($s),this.boundingSphere.union(ac)}copy(e,t){return super.copy(e,t),this.instanceMatrix.copy(e.instanceMatrix),e.morphTexture!==null&&(this.morphTexture=e.morphTexture.clone()),e.instanceColor!==null&&(this.instanceColor=e.instanceColor.clone()),this.count=e.count,e.boundingBox!==null&&(this.boundingBox=e.boundingBox.clone()),e.boundingSphere!==null&&(this.boundingSphere=e.boundingSphere.clone()),this}getColorAt(e,t){t.fromArray(this.instanceColor.array,e*3)}getMatrixAt(e,t){t.fromArray(this.instanceMatrix.array,e*16)}getMorphAt(e,t){let n=t.morphTargetInfluences,r=this.morphTexture.source.data.data,i=e*(n.length+1)+1;for(let e=0;e<n.length;e++)n[e]=r[i+e]}raycast(e,t){let n=this.matrixWorld,r=this.count;if(ic.geometry=this.geometry,ic.material=this.material,ic.material!==void 0&&(this.boundingSphere===null&&this.computeBoundingSphere(),ac.copy(this.boundingSphere),ac.applyMatrix4(n),e.ray.intersectsSphere(ac)!==!1))for(let i=0;i<r;i++){this.getMatrixAt(i,$s),ec.multiplyMatrices(n,$s),ic.matrixWorld=ec,ic.raycast(e,tc);for(let e=0,n=tc.length;e<n;e++){let n=tc[e];n.instanceId=i,n.object=this,t.push(n)}tc.length=0}}setColorAt(e,t){this.instanceColor===null&&(this.instanceColor=new Qs(new Float32Array(this.instanceMatrix.count*3).fill(1),3)),t.toArray(this.instanceColor.array,e*3)}setMatrixAt(e,t){t.toArray(this.instanceMatrix.array,e*16)}setMorphAt(e,t){let n=t.morphTargetInfluences,r=n.length+1;this.morphTexture===null&&(this.morphTexture=new Zs(new Float32Array(r*this.count),r,this.count,A,v));let i=this.morphTexture.source.data.data,a=0;for(let e=0;e<n.length;e++)a+=n[e];let o=this.geometry.morphTargetsRelative?1:1-a,s=r*e;i[s]=o,i.set(n,s+1)}updateMorphTargets(){}dispose(){return this.dispatchEvent({type:`dispose`}),this.morphTexture!==null&&(this.morphTexture.dispose(),this.morphTexture=null),this}},sc=class extends gr{static get type(){return`LineBasicMaterial`}constructor(e){super(),this.isLineBasicMaterial=!0,this.color=new W(16777215),this.map=null,this.linewidth=1,this.linecap=`round`,this.linejoin=`round`,this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.linewidth=e.linewidth,this.linecap=e.linecap,this.linejoin=e.linejoin,this.fog=e.fog,this}},cc=new H,lc=new H,uc=new U,dc=new Sn,fc=new mn,pc=new H,mc=new H,hc=class extends Yn{constructor(e=new jr,t=new sc){super(),this.isLine=!0,this.type=`Line`,this.geometry=e,this.material=t,this.updateMorphTargets()}copy(e,t){return super.copy(e,t),this.material=Array.isArray(e.material)?e.material.slice():e.material,this.geometry=e.geometry,this}computeLineDistances(){let e=this.geometry;if(e.index===null){let t=e.attributes.position,n=[0];for(let e=1,r=t.count;e<r;e++)cc.fromBufferAttribute(t,e-1),lc.fromBufferAttribute(t,e),n[e]=n[e-1],n[e]+=cc.distanceTo(lc);e.setAttribute(`lineDistance`,new Cr(n,1))}else console.warn(`THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.`);return this}raycast(e,t){let n=this.geometry,r=this.matrixWorld,i=e.params.Line.threshold,a=n.drawRange;if(n.boundingSphere===null&&n.computeBoundingSphere(),fc.copy(n.boundingSphere),fc.applyMatrix4(r),fc.radius+=i,e.ray.intersectsSphere(fc)===!1)return;uc.copy(r).invert(),dc.copy(e.ray).applyMatrix4(uc);let o=i/((this.scale.x+this.scale.y+this.scale.z)/3),s=o*o,c=this.isLineSegments?2:1,l=n.index,u=n.attributes.position;if(l!==null){let n=Math.max(0,a.start),r=Math.min(l.count,a.start+a.count);for(let i=n,a=r-1;i<a;i+=c){let n=l.getX(i),r=l.getX(i+1),a=gc(this,e,dc,s,n,r);a&&t.push(a)}if(this.isLineLoop){let i=l.getX(r-1),a=l.getX(n),o=gc(this,e,dc,s,i,a);o&&t.push(o)}}else{let n=Math.max(0,a.start),r=Math.min(u.count,a.start+a.count);for(let i=n,a=r-1;i<a;i+=c){let n=gc(this,e,dc,s,i,i+1);n&&t.push(n)}if(this.isLineLoop){let i=gc(this,e,dc,s,r-1,n);i&&t.push(i)}}}updateMorphTargets(){let e=this.geometry.morphAttributes,t=Object.keys(e);if(t.length>0){let n=e[t[0]];if(n!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let e=0,t=n.length;e<t;e++){let t=n[e].name||String(e);this.morphTargetInfluences.push(0),this.morphTargetDictionary[t]=e}}}}};function gc(e,t,n,r,i,a){let o=e.geometry.attributes.position;if(cc.fromBufferAttribute(o,i),lc.fromBufferAttribute(o,a),n.distanceSqToSegment(cc,lc,pc,mc)>r)return;pc.applyMatrix4(e.matrixWorld);let s=t.ray.origin.distanceTo(pc);if(!(s<t.near||s>t.far))return{distance:s,point:mc.clone().applyMatrix4(e.matrixWorld),index:i,face:null,faceIndex:null,barycoord:null,object:e}}var _c=new H,vc=new H,yc=class extends hc{constructor(e,t){super(e,t),this.isLineSegments=!0,this.type=`LineSegments`}computeLineDistances(){let e=this.geometry;if(e.index===null){let t=e.attributes.position,n=[];for(let e=0,r=t.count;e<r;e+=2)_c.fromBufferAttribute(t,e),vc.fromBufferAttribute(t,e+1),n[e]=e===0?0:n[e-1],n[e+1]=n[e]+_c.distanceTo(vc);e.setAttribute(`lineDistance`,new Cr(n,1))}else console.warn(`THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.`);return this}},bc=class extends gr{static get type(){return`PointsMaterial`}constructor(e){super(),this.isPointsMaterial=!0,this.color=new W(16777215),this.map=null,this.alphaMap=null,this.size=1,this.sizeAttenuation=!0,this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.alphaMap=e.alphaMap,this.size=e.size,this.sizeAttenuation=e.sizeAttenuation,this.fog=e.fog,this}},xc=new U,Sc=new Sn,Cc=new mn,wc=new H,Tc=class extends Yn{constructor(e=new jr,t=new bc){super(),this.isPoints=!0,this.type=`Points`,this.geometry=e,this.material=t,this.updateMorphTargets()}copy(e,t){return super.copy(e,t),this.material=Array.isArray(e.material)?e.material.slice():e.material,this.geometry=e.geometry,this}raycast(e,t){let n=this.geometry,r=this.matrixWorld,i=e.params.Points.threshold,a=n.drawRange;if(n.boundingSphere===null&&n.computeBoundingSphere(),Cc.copy(n.boundingSphere),Cc.applyMatrix4(r),Cc.radius+=i,e.ray.intersectsSphere(Cc)===!1)return;xc.copy(r).invert(),Sc.copy(e.ray).applyMatrix4(xc);let o=i/((this.scale.x+this.scale.y+this.scale.z)/3),s=o*o,c=n.index,l=n.attributes.position;if(c!==null){let n=Math.max(0,a.start),i=Math.min(c.count,a.start+a.count);for(let a=n,o=i;a<o;a++){let n=c.getX(a);wc.fromBufferAttribute(l,n),Ec(wc,n,s,r,e,t,this)}}else{let n=Math.max(0,a.start),i=Math.min(l.count,a.start+a.count);for(let a=n,o=i;a<o;a++)wc.fromBufferAttribute(l,a),Ec(wc,a,s,r,e,t,this)}}updateMorphTargets(){let e=this.geometry.morphAttributes,t=Object.keys(e);if(t.length>0){let n=e[t[0]];if(n!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let e=0,t=n.length;e<t;e++){let t=n[e].name||String(e);this.morphTargetInfluences.push(0),this.morphTargetDictionary[t]=e}}}}};function Ec(e,t,n,r,i,a,o){let s=Sc.distanceSqToPoint(e);if(s<n){let n=new H;Sc.closestPointToPoint(e,n),n.applyMatrix4(r);let c=i.ray.origin.distanceTo(n);if(c<i.near||c>i.far)return;a.push({distance:c,distanceToRay:Math.sqrt(s),point:n,index:t,face:null,faceIndex:null,barycoord:null,object:o})}}var Dc=class extends Ht{constructor(e,t){super({width:e,height:t}),this.isFramebufferTexture=!0,this.magFilter=o,this.minFilter=o,this.generateMipmaps=!1,this.needsUpdate=!0}},Oc=class extends Ht{constructor(e,t,n,r,i,a,o,s,c){super(e,t,n,r,i,a,o,s,c),this.isCanvasTexture=!0,this.needsUpdate=!0}},kc=class{constructor(){this.type=`Curve`,this.arcLengthDivisions=200}getPoint(){return console.warn(`THREE.Curve: .getPoint() not implemented.`),null}getPointAt(e,t){let n=this.getUtoTmapping(e);return this.getPoint(n,t)}getPoints(e=5){let t=[];for(let n=0;n<=e;n++)t.push(this.getPoint(n/e));return t}getSpacedPoints(e=5){let t=[];for(let n=0;n<=e;n++)t.push(this.getPointAt(n/e));return t}getLength(){let e=this.getLengths();return e[e.length-1]}getLengths(e=this.arcLengthDivisions){if(this.cacheArcLengths&&this.cacheArcLengths.length===e+1&&!this.needsUpdate)return this.cacheArcLengths;this.needsUpdate=!1;let t=[],n,r=this.getPoint(0),i=0;t.push(0);for(let a=1;a<=e;a++)n=this.getPoint(a/e),i+=n.distanceTo(r),t.push(i),r=n;return this.cacheArcLengths=t,t}updateArcLengths(){this.needsUpdate=!0,this.getLengths()}getUtoTmapping(e,t){let n=this.getLengths(),r=0,i=n.length,a;a=t||e*n[i-1];let o=0,s=i-1,c;for(;o<=s;)if(r=Math.floor(o+(s-o)/2),c=n[r]-a,c<0)o=r+1;else if(c>0)s=r-1;else{s=r;break}if(r=s,n[r]===a)return r/(i-1);let l=n[r],u=n[r+1]-l,d=(a-l)/u;return(r+d)/(i-1)}getTangent(e,t){let n=1e-4,r=e-n,i=e+n;r<0&&(r=0),i>1&&(i=1);let a=this.getPoint(r),o=this.getPoint(i),s=t||(a.isVector2?new R:new H);return s.copy(o).sub(a).normalize(),s}getTangentAt(e,t){let n=this.getUtoTmapping(e);return this.getTangent(n,t)}computeFrenetFrames(e,t){let n=new H,r=[],i=[],a=[],o=new H,s=new U;for(let t=0;t<=e;t++){let n=t/e;r[t]=this.getTangentAt(n,new H)}i[0]=new H,a[0]=new H;let c=Number.MAX_VALUE,l=Math.abs(r[0].x),u=Math.abs(r[0].y),d=Math.abs(r[0].z);l<=c&&(c=l,n.set(1,0,0)),u<=c&&(c=u,n.set(0,1,0)),d<=c&&n.set(0,0,1),o.crossVectors(r[0],n).normalize(),i[0].crossVectors(r[0],o),a[0].crossVectors(r[0],i[0]);for(let t=1;t<=e;t++){if(i[t]=i[t-1].clone(),a[t]=a[t-1].clone(),o.crossVectors(r[t-1],r[t]),o.length()>2**-52){o.normalize();let e=Math.acos(Ze(r[t-1].dot(r[t]),-1,1));i[t].applyMatrix4(s.makeRotationAxis(o,e))}a[t].crossVectors(r[t],i[t])}if(t===!0){let t=Math.acos(Ze(i[0].dot(i[e]),-1,1));t/=e,r[0].dot(o.crossVectors(i[0],i[e]))>0&&(t=-t);for(let n=1;n<=e;n++)i[n].applyMatrix4(s.makeRotationAxis(r[n],t*n)),a[n].crossVectors(r[n],i[n])}return{tangents:r,normals:i,binormals:a}}clone(){return new this.constructor().copy(this)}copy(e){return this.arcLengthDivisions=e.arcLengthDivisions,this}toJSON(){let e={metadata:{version:4.6,type:`Curve`,generator:`Curve.toJSON`}};return e.arcLengthDivisions=this.arcLengthDivisions,e.type=this.type,e}fromJSON(e){return this.arcLengthDivisions=e.arcLengthDivisions,this}},Ac=class extends kc{constructor(e=0,t=0,n=1,r=1,i=0,a=Math.PI*2,o=!1,s=0){super(),this.isEllipseCurve=!0,this.type=`EllipseCurve`,this.aX=e,this.aY=t,this.xRadius=n,this.yRadius=r,this.aStartAngle=i,this.aEndAngle=a,this.aClockwise=o,this.aRotation=s}getPoint(e,t=new R){let n=t,r=Math.PI*2,i=this.aEndAngle-this.aStartAngle,a=Math.abs(i)<2**-52;for(;i<0;)i+=r;for(;i>r;)i-=r;i<2**-52&&(i=a?0:r),this.aClockwise===!0&&!a&&(i===r?i=-r:i-=r);let o=this.aStartAngle+e*i,s=this.aX+this.xRadius*Math.cos(o),c=this.aY+this.yRadius*Math.sin(o);if(this.aRotation!==0){let e=Math.cos(this.aRotation),t=Math.sin(this.aRotation),n=s-this.aX,r=c-this.aY;s=n*e-r*t+this.aX,c=n*t+r*e+this.aY}return n.set(s,c)}copy(e){return super.copy(e),this.aX=e.aX,this.aY=e.aY,this.xRadius=e.xRadius,this.yRadius=e.yRadius,this.aStartAngle=e.aStartAngle,this.aEndAngle=e.aEndAngle,this.aClockwise=e.aClockwise,this.aRotation=e.aRotation,this}toJSON(){let e=super.toJSON();return e.aX=this.aX,e.aY=this.aY,e.xRadius=this.xRadius,e.yRadius=this.yRadius,e.aStartAngle=this.aStartAngle,e.aEndAngle=this.aEndAngle,e.aClockwise=this.aClockwise,e.aRotation=this.aRotation,e}fromJSON(e){return super.fromJSON(e),this.aX=e.aX,this.aY=e.aY,this.xRadius=e.xRadius,this.yRadius=e.yRadius,this.aStartAngle=e.aStartAngle,this.aEndAngle=e.aEndAngle,this.aClockwise=e.aClockwise,this.aRotation=e.aRotation,this}},jc=class extends Ac{constructor(e,t,n,r,i,a){super(e,t,n,n,r,i,a),this.isArcCurve=!0,this.type=`ArcCurve`}};function Mc(){let e=0,t=0,n=0,r=0;function i(i,a,o,s){e=i,t=o,n=-3*i+3*a-2*o-s,r=2*i-2*a+o+s}return{initCatmullRom:function(e,t,n,r,a){i(t,n,a*(n-e),a*(r-t))},initNonuniformCatmullRom:function(e,t,n,r,a,o,s){let c=(t-e)/a-(n-e)/(a+o)+(n-t)/o,l=(n-t)/o-(r-t)/(o+s)+(r-n)/s;c*=o,l*=o,i(t,n,c,l)},calc:function(i){let a=i*i,o=a*i;return e+t*i+n*a+r*o}}}var Nc=new H,Pc=new Mc,Fc=new Mc,Ic=new Mc,Lc=class extends kc{constructor(e=[],t=!1,n=`centripetal`,r=.5){super(),this.isCatmullRomCurve3=!0,this.type=`CatmullRomCurve3`,this.points=e,this.closed=t,this.curveType=n,this.tension=r}getPoint(e,t=new H){let n=t,r=this.points,i=r.length,a=(i-+!this.closed)*e,o=Math.floor(a),s=a-o;this.closed?o+=o>0?0:(Math.floor(Math.abs(o)/i)+1)*i:s===0&&o===i-1&&(o=i-2,s=1);let c,l;this.closed||o>0?c=r[(o-1)%i]:(Nc.subVectors(r[0],r[1]).add(r[0]),c=Nc);let u=r[o%i],d=r[(o+1)%i];if(this.closed||o+2<i?l=r[(o+2)%i]:(Nc.subVectors(r[i-1],r[i-2]).add(r[i-1]),l=Nc),this.curveType===`centripetal`||this.curveType===`chordal`){let e=this.curveType===`chordal`?.5:.25,t=c.distanceToSquared(u)**+e,n=u.distanceToSquared(d)**+e,r=d.distanceToSquared(l)**+e;n<1e-4&&(n=1),t<1e-4&&(t=n),r<1e-4&&(r=n),Pc.initNonuniformCatmullRom(c.x,u.x,d.x,l.x,t,n,r),Fc.initNonuniformCatmullRom(c.y,u.y,d.y,l.y,t,n,r),Ic.initNonuniformCatmullRom(c.z,u.z,d.z,l.z,t,n,r)}else this.curveType===`catmullrom`&&(Pc.initCatmullRom(c.x,u.x,d.x,l.x,this.tension),Fc.initCatmullRom(c.y,u.y,d.y,l.y,this.tension),Ic.initCatmullRom(c.z,u.z,d.z,l.z,this.tension));return n.set(Pc.calc(s),Fc.calc(s),Ic.calc(s)),n}copy(e){super.copy(e),this.points=[];for(let t=0,n=e.points.length;t<n;t++){let n=e.points[t];this.points.push(n.clone())}return this.closed=e.closed,this.curveType=e.curveType,this.tension=e.tension,this}toJSON(){let e=super.toJSON();e.points=[];for(let t=0,n=this.points.length;t<n;t++){let n=this.points[t];e.points.push(n.toArray())}return e.closed=this.closed,e.curveType=this.curveType,e.tension=this.tension,e}fromJSON(e){super.fromJSON(e),this.points=[];for(let t=0,n=e.points.length;t<n;t++){let n=e.points[t];this.points.push(new H().fromArray(n))}return this.closed=e.closed,this.curveType=e.curveType,this.tension=e.tension,this}};function Rc(e,t,n,r,i){let a=(r-t)*.5,o=(i-n)*.5,s=e*e,c=e*s;return(2*n-2*r+a+o)*c+(-3*n+3*r-2*a-o)*s+a*e+n}function zc(e,t){let n=1-e;return n*n*t}function Bc(e,t){return 2*(1-e)*e*t}function Vc(e,t){return e*e*t}function Hc(e,t,n,r){return zc(e,t)+Bc(e,n)+Vc(e,r)}function Uc(e,t){let n=1-e;return n*n*n*t}function Wc(e,t){let n=1-e;return 3*n*n*e*t}function Gc(e,t){return 3*(1-e)*e*e*t}function Kc(e,t){return e*e*e*t}function qc(e,t,n,r,i){return Uc(e,t)+Wc(e,n)+Gc(e,r)+Kc(e,i)}var Jc=class extends kc{constructor(e=new R,t=new R,n=new R,r=new R){super(),this.isCubicBezierCurve=!0,this.type=`CubicBezierCurve`,this.v0=e,this.v1=t,this.v2=n,this.v3=r}getPoint(e,t=new R){let n=t,r=this.v0,i=this.v1,a=this.v2,o=this.v3;return n.set(qc(e,r.x,i.x,a.x,o.x),qc(e,r.y,i.y,a.y,o.y)),n}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this.v3.copy(e.v3),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e.v3=this.v3.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this.v3.fromArray(e.v3),this}},Yc=class extends kc{constructor(e=new H,t=new H,n=new H,r=new H){super(),this.isCubicBezierCurve3=!0,this.type=`CubicBezierCurve3`,this.v0=e,this.v1=t,this.v2=n,this.v3=r}getPoint(e,t=new H){let n=t,r=this.v0,i=this.v1,a=this.v2,o=this.v3;return n.set(qc(e,r.x,i.x,a.x,o.x),qc(e,r.y,i.y,a.y,o.y),qc(e,r.z,i.z,a.z,o.z)),n}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this.v3.copy(e.v3),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e.v3=this.v3.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this.v3.fromArray(e.v3),this}},Xc=class extends kc{constructor(e=new R,t=new R){super(),this.isLineCurve=!0,this.type=`LineCurve`,this.v1=e,this.v2=t}getPoint(e,t=new R){let n=t;return e===1?n.copy(this.v2):(n.copy(this.v2).sub(this.v1),n.multiplyScalar(e).add(this.v1)),n}getPointAt(e,t){return this.getPoint(e,t)}getTangent(e,t=new R){return t.subVectors(this.v2,this.v1).normalize()}getTangentAt(e,t){return this.getTangent(e,t)}copy(e){return super.copy(e),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},Zc=class extends kc{constructor(e=new H,t=new H){super(),this.isLineCurve3=!0,this.type=`LineCurve3`,this.v1=e,this.v2=t}getPoint(e,t=new H){let n=t;return e===1?n.copy(this.v2):(n.copy(this.v2).sub(this.v1),n.multiplyScalar(e).add(this.v1)),n}getPointAt(e,t){return this.getPoint(e,t)}getTangent(e,t=new H){return t.subVectors(this.v2,this.v1).normalize()}getTangentAt(e,t){return this.getTangent(e,t)}copy(e){return super.copy(e),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},Qc=class extends kc{constructor(e=new R,t=new R,n=new R){super(),this.isQuadraticBezierCurve=!0,this.type=`QuadraticBezierCurve`,this.v0=e,this.v1=t,this.v2=n}getPoint(e,t=new R){let n=t,r=this.v0,i=this.v1,a=this.v2;return n.set(Hc(e,r.x,i.x,a.x),Hc(e,r.y,i.y,a.y)),n}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},$c=class extends kc{constructor(e=new H,t=new H,n=new H){super(),this.isQuadraticBezierCurve3=!0,this.type=`QuadraticBezierCurve3`,this.v0=e,this.v1=t,this.v2=n}getPoint(e,t=new H){let n=t,r=this.v0,i=this.v1,a=this.v2;return n.set(Hc(e,r.x,i.x,a.x),Hc(e,r.y,i.y,a.y),Hc(e,r.z,i.z,a.z)),n}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},el=class extends kc{constructor(e=[]){super(),this.isSplineCurve=!0,this.type=`SplineCurve`,this.points=e}getPoint(e,t=new R){let n=t,r=this.points,i=(r.length-1)*e,a=Math.floor(i),o=i-a,s=r[a===0?a:a-1],c=r[a],l=r[a>r.length-2?r.length-1:a+1],u=r[a>r.length-3?r.length-1:a+2];return n.set(Rc(o,s.x,c.x,l.x,u.x),Rc(o,s.y,c.y,l.y,u.y)),n}copy(e){super.copy(e),this.points=[];for(let t=0,n=e.points.length;t<n;t++){let n=e.points[t];this.points.push(n.clone())}return this}toJSON(){let e=super.toJSON();e.points=[];for(let t=0,n=this.points.length;t<n;t++){let n=this.points[t];e.points.push(n.toArray())}return e}fromJSON(e){super.fromJSON(e),this.points=[];for(let t=0,n=e.points.length;t<n;t++){let n=e.points[t];this.points.push(new R().fromArray(n))}return this}},tl=Object.freeze({__proto__:null,ArcCurve:jc,CatmullRomCurve3:Lc,CubicBezierCurve:Jc,CubicBezierCurve3:Yc,EllipseCurve:Ac,LineCurve:Xc,LineCurve3:Zc,QuadraticBezierCurve:Qc,QuadraticBezierCurve3:$c,SplineCurve:el}),nl=class extends kc{constructor(){super(),this.type=`CurvePath`,this.curves=[],this.autoClose=!1}add(e){this.curves.push(e)}closePath(){let e=this.curves[0].getPoint(0),t=this.curves[this.curves.length-1].getPoint(1);if(!e.equals(t)){let n=e.isVector2===!0?`LineCurve`:`LineCurve3`;this.curves.push(new tl[n](t,e))}return this}getPoint(e,t){let n=e*this.getLength(),r=this.getCurveLengths(),i=0;for(;i<r.length;){if(r[i]>=n){let e=r[i]-n,a=this.curves[i],o=a.getLength(),s=o===0?0:1-e/o;return a.getPointAt(s,t)}i++}return null}getLength(){let e=this.getCurveLengths();return e[e.length-1]}updateArcLengths(){this.needsUpdate=!0,this.cacheLengths=null,this.getCurveLengths()}getCurveLengths(){if(this.cacheLengths&&this.cacheLengths.length===this.curves.length)return this.cacheLengths;let e=[],t=0;for(let n=0,r=this.curves.length;n<r;n++)t+=this.curves[n].getLength(),e.push(t);return this.cacheLengths=e,e}getSpacedPoints(e=40){let t=[];for(let n=0;n<=e;n++)t.push(this.getPoint(n/e));return this.autoClose&&t.push(t[0]),t}getPoints(e=12){let t=[],n;for(let r=0,i=this.curves;r<i.length;r++){let a=i[r],o=a.isEllipseCurve?e*2:a.isLineCurve||a.isLineCurve3?1:a.isSplineCurve?e*a.points.length:e,s=a.getPoints(o);for(let e=0;e<s.length;e++){let r=s[e];n&&n.equals(r)||(t.push(r),n=r)}}return this.autoClose&&t.length>1&&!t[t.length-1].equals(t[0])&&t.push(t[0]),t}copy(e){super.copy(e),this.curves=[];for(let t=0,n=e.curves.length;t<n;t++){let n=e.curves[t];this.curves.push(n.clone())}return this.autoClose=e.autoClose,this}toJSON(){let e=super.toJSON();e.autoClose=this.autoClose,e.curves=[];for(let t=0,n=this.curves.length;t<n;t++){let n=this.curves[t];e.curves.push(n.toJSON())}return e}fromJSON(e){super.fromJSON(e),this.autoClose=e.autoClose,this.curves=[];for(let t=0,n=e.curves.length;t<n;t++){let n=e.curves[t];this.curves.push(new tl[n.type]().fromJSON(n))}return this}},rl=class extends nl{constructor(e){super(),this.type=`Path`,this.currentPoint=new R,e&&this.setFromPoints(e)}setFromPoints(e){this.moveTo(e[0].x,e[0].y);for(let t=1,n=e.length;t<n;t++)this.lineTo(e[t].x,e[t].y);return this}moveTo(e,t){return this.currentPoint.set(e,t),this}lineTo(e,t){let n=new Xc(this.currentPoint.clone(),new R(e,t));return this.curves.push(n),this.currentPoint.set(e,t),this}quadraticCurveTo(e,t,n,r){let i=new Qc(this.currentPoint.clone(),new R(e,t),new R(n,r));return this.curves.push(i),this.currentPoint.set(n,r),this}bezierCurveTo(e,t,n,r,i,a){let o=new Jc(this.currentPoint.clone(),new R(e,t),new R(n,r),new R(i,a));return this.curves.push(o),this.currentPoint.set(i,a),this}splineThru(e){let t=new el([this.currentPoint.clone()].concat(e));return this.curves.push(t),this.currentPoint.copy(e[e.length-1]),this}arc(e,t,n,r,i,a){let o=this.currentPoint.x,s=this.currentPoint.y;return this.absarc(e+o,t+s,n,r,i,a),this}absarc(e,t,n,r,i,a){return this.absellipse(e,t,n,n,r,i,a),this}ellipse(e,t,n,r,i,a,o,s){let c=this.currentPoint.x,l=this.currentPoint.y;return this.absellipse(e+c,t+l,n,r,i,a,o,s),this}absellipse(e,t,n,r,i,a,o,s){let c=new Ac(e,t,n,r,i,a,o,s);if(this.curves.length>0){let e=c.getPoint(0);e.equals(this.currentPoint)||this.lineTo(e.x,e.y)}this.curves.push(c);let l=c.getPoint(1);return this.currentPoint.copy(l),this}copy(e){return super.copy(e),this.currentPoint.copy(e.currentPoint),this}toJSON(){let e=super.toJSON();return e.currentPoint=this.currentPoint.toArray(),e}fromJSON(e){return super.fromJSON(e),this.currentPoint.fromArray(e.currentPoint),this}},il=class e extends jr{constructor(e=[new R(0,-.5),new R(.5,0),new R(0,.5)],t=12,n=0,r=Math.PI*2){super(),this.type=`LatheGeometry`,this.parameters={points:e,segments:t,phiStart:n,phiLength:r},t=Math.floor(t),r=Ze(r,0,Math.PI*2);let i=[],a=[],o=[],s=[],c=[],l=1/t,u=new H,d=new R,f=new H,p=new H,m=new H,h=0,g=0;for(let t=0;t<=e.length-1;t++)switch(t){case 0:h=e[t+1].x-e[t].x,g=e[t+1].y-e[t].y,f.x=g*1,f.y=-h,f.z=g*0,m.copy(f),f.normalize(),s.push(f.x,f.y,f.z);break;case e.length-1:s.push(m.x,m.y,m.z);break;default:h=e[t+1].x-e[t].x,g=e[t+1].y-e[t].y,f.x=g*1,f.y=-h,f.z=g*0,p.copy(f),f.x+=m.x,f.y+=m.y,f.z+=m.z,f.normalize(),s.push(f.x,f.y,f.z),m.copy(p)}for(let i=0;i<=t;i++){let f=n+i*l*r,p=Math.sin(f),m=Math.cos(f);for(let n=0;n<=e.length-1;n++){u.x=e[n].x*p,u.y=e[n].y,u.z=e[n].x*m,a.push(u.x,u.y,u.z),d.x=i/t,d.y=n/(e.length-1),o.push(d.x,d.y);let r=s[3*n+0]*p,l=s[3*n+1],f=s[3*n+0]*m;c.push(r,l,f)}}for(let n=0;n<t;n++)for(let t=0;t<e.length-1;t++){let r=t+n*e.length,a=r,o=r+e.length,s=r+e.length+1,c=r+1;i.push(a,o,c),i.push(s,c,o)}this.setIndex(i),this.setAttribute(`position`,new Cr(a,3)),this.setAttribute(`uv`,new Cr(o,2)),this.setAttribute(`normal`,new Cr(c,3))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(t){return new e(t.points,t.segments,t.phiStart,t.phiLength)}},al=class e extends il{constructor(e=1,t=1,n=4,r=8){let i=new rl;i.absarc(0,-t/2,e,Math.PI*1.5,0),i.absarc(0,t/2,e,0,Math.PI*.5),super(i.getPoints(n),r),this.type=`CapsuleGeometry`,this.parameters={radius:e,length:t,capSegments:n,radialSegments:r}}static fromJSON(t){return new e(t.radius,t.length,t.capSegments,t.radialSegments)}},ol=class e extends jr{constructor(e=1,t=32,n=0,r=Math.PI*2){super(),this.type=`CircleGeometry`,this.parameters={radius:e,segments:t,thetaStart:n,thetaLength:r},t=Math.max(3,t);let i=[],a=[],o=[],s=[],c=new H,l=new R;a.push(0,0,0),o.push(0,0,1),s.push(.5,.5);for(let i=0,u=3;i<=t;i++,u+=3){let d=n+i/t*r;c.x=e*Math.cos(d),c.y=e*Math.sin(d),a.push(c.x,c.y,c.z),o.push(0,0,1),l.x=(a[u]/e+1)/2,l.y=(a[u+1]/e+1)/2,s.push(l.x,l.y)}for(let e=1;e<=t;e++)i.push(e,e+1,0);this.setIndex(i),this.setAttribute(`position`,new Cr(a,3)),this.setAttribute(`normal`,new Cr(o,3)),this.setAttribute(`uv`,new Cr(s,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(t){return new e(t.radius,t.segments,t.thetaStart,t.thetaLength)}},sl=class e extends jr{constructor(e=1,t=1,n=1,r=32,i=1,a=!1,o=0,s=Math.PI*2){super(),this.type=`CylinderGeometry`,this.parameters={radiusTop:e,radiusBottom:t,height:n,radialSegments:r,heightSegments:i,openEnded:a,thetaStart:o,thetaLength:s};let c=this;r=Math.floor(r),i=Math.floor(i);let l=[],u=[],d=[],f=[],p=0,m=[],h=n/2,g=0;_(),a===!1&&(e>0&&v(!0),t>0&&v(!1)),this.setIndex(l),this.setAttribute(`position`,new Cr(u,3)),this.setAttribute(`normal`,new Cr(d,3)),this.setAttribute(`uv`,new Cr(f,2));function _(){let a=new H,_=new H,v=0,y=(t-e)/n;for(let c=0;c<=i;c++){let l=[],g=c/i,v=g*(t-e)+e;for(let e=0;e<=r;e++){let t=e/r,i=t*s+o,c=Math.sin(i),m=Math.cos(i);_.x=v*c,_.y=-g*n+h,_.z=v*m,u.push(_.x,_.y,_.z),a.set(c,y,m).normalize(),d.push(a.x,a.y,a.z),f.push(t,1-g),l.push(p++)}m.push(l)}for(let n=0;n<r;n++)for(let r=0;r<i;r++){let a=m[r][n],o=m[r+1][n],s=m[r+1][n+1],c=m[r][n+1];(e>0||r!==0)&&(l.push(a,o,c),v+=3),(t>0||r!==i-1)&&(l.push(o,s,c),v+=3)}c.addGroup(g,v,0),g+=v}function v(n){let i=p,a=new R,m=new H,_=0,v=n===!0?e:t,y=n===!0?1:-1;for(let e=1;e<=r;e++)u.push(0,h*y,0),d.push(0,y,0),f.push(.5,.5),p++;let b=p;for(let e=0;e<=r;e++){let t=e/r*s+o,n=Math.cos(t),i=Math.sin(t);m.x=v*i,m.y=h*y,m.z=v*n,u.push(m.x,m.y,m.z),d.push(0,y,0),a.x=n*.5+.5,a.y=i*.5*y+.5,f.push(a.x,a.y),p++}for(let e=0;e<r;e++){let t=i+e,r=b+e;n===!0?l.push(r,r+1,t):l.push(r+1,r,t),_+=3}c.addGroup(g,_,n===!0?1:2),g+=_}}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(t){return new e(t.radiusTop,t.radiusBottom,t.height,t.radialSegments,t.heightSegments,t.openEnded,t.thetaStart,t.thetaLength)}},cl=class e extends sl{constructor(e=1,t=1,n=32,r=1,i=!1,a=0,o=Math.PI*2){super(0,e,t,n,r,i,a,o),this.type=`ConeGeometry`,this.parameters={radius:e,height:t,radialSegments:n,heightSegments:r,openEnded:i,thetaStart:a,thetaLength:o}}static fromJSON(t){return new e(t.radius,t.height,t.radialSegments,t.heightSegments,t.openEnded,t.thetaStart,t.thetaLength)}},ll=class e extends jr{constructor(e=1,t=32,n=16,r=0,i=Math.PI*2,a=0,o=Math.PI){super(),this.type=`SphereGeometry`,this.parameters={radius:e,widthSegments:t,heightSegments:n,phiStart:r,phiLength:i,thetaStart:a,thetaLength:o},t=Math.max(3,Math.floor(t)),n=Math.max(2,Math.floor(n));let s=Math.min(a+o,Math.PI),c=0,l=[],u=new H,d=new H,f=[],p=[],m=[],h=[];for(let f=0;f<=n;f++){let g=[],_=f/n,v=0;f===0&&a===0?v=.5/t:f===n&&s===Math.PI&&(v=-.5/t);for(let n=0;n<=t;n++){let s=n/t;u.x=-e*Math.cos(r+s*i)*Math.sin(a+_*o),u.y=e*Math.cos(a+_*o),u.z=e*Math.sin(r+s*i)*Math.sin(a+_*o),p.push(u.x,u.y,u.z),d.copy(u).normalize(),m.push(d.x,d.y,d.z),h.push(s+v,1-_),g.push(c++)}l.push(g)}for(let e=0;e<n;e++)for(let r=0;r<t;r++){let t=l[e][r+1],i=l[e][r],o=l[e+1][r],c=l[e+1][r+1];(e!==0||a>0)&&f.push(t,i,c),(e!==n-1||s<Math.PI)&&f.push(i,o,c)}this.setIndex(f),this.setAttribute(`position`,new Cr(p,3)),this.setAttribute(`normal`,new Cr(m,3)),this.setAttribute(`uv`,new Cr(h,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(t){return new e(t.radius,t.widthSegments,t.heightSegments,t.phiStart,t.phiLength,t.thetaStart,t.thetaLength)}},ul=class extends gr{static get type(){return`MeshLambertMaterial`}constructor(e){super(),this.isMeshLambertMaterial=!0,this.color=new W(16777215),this.map=null,this.lightMap=null,this.lightMapIntensity=1,this.aoMap=null,this.aoMapIntensity=1,this.emissive=new W(0),this.emissiveIntensity=1,this.emissiveMap=null,this.bumpMap=null,this.bumpScale=1,this.normalMap=null,this.normalMapType=0,this.normalScale=new R(1,1),this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.specularMap=null,this.alphaMap=null,this.envMap=null,this.envMapRotation=new Mn,this.combine=0,this.reflectivity=1,this.refractionRatio=.98,this.wireframe=!1,this.wireframeLinewidth=1,this.wireframeLinecap=`round`,this.wireframeLinejoin=`round`,this.flatShading=!1,this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.lightMap=e.lightMap,this.lightMapIntensity=e.lightMapIntensity,this.aoMap=e.aoMap,this.aoMapIntensity=e.aoMapIntensity,this.emissive.copy(e.emissive),this.emissiveMap=e.emissiveMap,this.emissiveIntensity=e.emissiveIntensity,this.bumpMap=e.bumpMap,this.bumpScale=e.bumpScale,this.normalMap=e.normalMap,this.normalMapType=e.normalMapType,this.normalScale.copy(e.normalScale),this.displacementMap=e.displacementMap,this.displacementScale=e.displacementScale,this.displacementBias=e.displacementBias,this.specularMap=e.specularMap,this.alphaMap=e.alphaMap,this.envMap=e.envMap,this.envMapRotation.copy(e.envMapRotation),this.combine=e.combine,this.reflectivity=e.reflectivity,this.refractionRatio=e.refractionRatio,this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this.wireframeLinecap=e.wireframeLinecap,this.wireframeLinejoin=e.wireframeLinejoin,this.flatShading=e.flatShading,this.fog=e.fog,this}};function dl(e,t,n){return!e||!n&&e.constructor===t?e:typeof t.BYTES_PER_ELEMENT==`number`?new t(e):Array.prototype.slice.call(e)}function fl(e){return ArrayBuffer.isView(e)&&!(e instanceof DataView)}var pl=class{constructor(e,t,n,r){this.parameterPositions=e,this._cachedIndex=0,this.resultBuffer=r===void 0?new t.constructor(n):r,this.sampleValues=t,this.valueSize=n,this.settings=null,this.DefaultSettings_={}}evaluate(e){let t=this.parameterPositions,n=this._cachedIndex,r=t[n],i=t[n-1];validate_interval:{seek:{let a;linear_scan:{forward_scan:if(!(e<r)){for(let a=n+2;;){if(r===void 0){if(e<i)break forward_scan;return n=t.length,this._cachedIndex=n,this.copySampleValue_(n-1)}if(n===a)break;if(i=r,r=t[++n],e<r)break seek}a=t.length;break linear_scan}if(!(e>=i)){let o=t[1];e<o&&(n=2,i=o);for(let a=n-2;;){if(i===void 0)return this._cachedIndex=0,this.copySampleValue_(0);if(n===a)break;if(r=i,i=t[--n-1],e>=i)break seek}a=n,n=0;break linear_scan}break validate_interval}for(;n<a;){let r=n+a>>>1;e<t[r]?a=r:n=r+1}if(r=t[n],i=t[n-1],i===void 0)return this._cachedIndex=0,this.copySampleValue_(0);if(r===void 0)return n=t.length,this._cachedIndex=n,this.copySampleValue_(n-1)}this._cachedIndex=n,this.intervalChanged_(n,i,r)}return this.interpolate_(n,i,e,r)}getSettings_(){return this.settings||this.DefaultSettings_}copySampleValue_(e){let t=this.resultBuffer,n=this.sampleValues,r=this.valueSize,i=e*r;for(let e=0;e!==r;++e)t[e]=n[i+e];return t}interpolate_(){throw Error(`call to abstract method`)}intervalChanged_(){}},ml=class extends pl{constructor(e,t,n,r){super(e,t,n,r),this._weightPrev=-0,this._offsetPrev=-0,this._weightNext=-0,this._offsetNext=-0,this.DefaultSettings_={endingStart:Ne,endingEnd:Ne}}intervalChanged_(e,t,n){let r=this.parameterPositions,i=e-2,a=e+1,o=r[i],s=r[a];if(o===void 0)switch(this.getSettings_().endingStart){case Pe:i=e,o=2*t-n;break;case Fe:i=r.length-2,o=t+r[i]-r[i+1];break;default:i=e,o=n}if(s===void 0)switch(this.getSettings_().endingEnd){case Pe:a=e,s=2*n-t;break;case Fe:a=1,s=n+r[1]-r[0];break;default:a=e-1,s=t}let c=(n-t)*.5,l=this.valueSize;this._weightPrev=c/(t-o),this._weightNext=c/(s-n),this._offsetPrev=i*l,this._offsetNext=a*l}interpolate_(e,t,n,r){let i=this.resultBuffer,a=this.sampleValues,o=this.valueSize,s=e*o,c=s-o,l=this._offsetPrev,u=this._offsetNext,d=this._weightPrev,f=this._weightNext,p=(n-t)/(r-t),m=p*p,h=m*p,g=-d*h+2*d*m-d*p,_=(1+d)*h+(-1.5-2*d)*m+(-.5+d)*p+1,v=(-1-f)*h+(1.5+f)*m+.5*p,y=f*h-f*m;for(let e=0;e!==o;++e)i[e]=g*a[l+e]+_*a[c+e]+v*a[s+e]+y*a[u+e];return i}},hl=class extends pl{constructor(e,t,n,r){super(e,t,n,r)}interpolate_(e,t,n,r){let i=this.resultBuffer,a=this.sampleValues,o=this.valueSize,s=e*o,c=s-o,l=(n-t)/(r-t),u=1-l;for(let e=0;e!==o;++e)i[e]=a[c+e]*u+a[s+e]*l;return i}},gl=class extends pl{constructor(e,t,n,r){super(e,t,n,r)}interpolate_(e){return this.copySampleValue_(e-1)}},_l=class{constructor(e,t,n,r){if(e===void 0)throw Error(`THREE.KeyframeTrack: track name is undefined`);if(t===void 0||t.length===0)throw Error(`THREE.KeyframeTrack: no keyframes in track named `+e);this.name=e,this.times=dl(t,this.TimeBufferType),this.values=dl(n,this.ValueBufferType),this.setInterpolation(r||this.DefaultInterpolation)}static toJSON(e){let t=e.constructor,n;if(t.toJSON!==this.toJSON)n=t.toJSON(e);else{n={name:e.name,times:dl(e.times,Array),values:dl(e.values,Array)};let t=e.getInterpolation();t!==e.DefaultInterpolation&&(n.interpolation=t)}return n.type=e.ValueTypeName,n}InterpolantFactoryMethodDiscrete(e){return new gl(this.times,this.values,this.getValueSize(),e)}InterpolantFactoryMethodLinear(e){return new hl(this.times,this.values,this.getValueSize(),e)}InterpolantFactoryMethodSmooth(e){return new ml(this.times,this.values,this.getValueSize(),e)}setInterpolation(e){let t;switch(e){case Ae:t=this.InterpolantFactoryMethodDiscrete;break;case je:t=this.InterpolantFactoryMethodLinear;break;case Me:t=this.InterpolantFactoryMethodSmooth}if(t===void 0){let t=`unsupported interpolation for `+this.ValueTypeName+` keyframe track named `+this.name;if(this.createInterpolant===void 0){if(e!==this.DefaultInterpolation)this.setInterpolation(this.DefaultInterpolation);else throw Error(t)}return console.warn(`THREE.KeyframeTrack:`,t),this}return this.createInterpolant=t,this}getInterpolation(){switch(this.createInterpolant){case this.InterpolantFactoryMethodDiscrete:return Ae;case this.InterpolantFactoryMethodLinear:return je;case this.InterpolantFactoryMethodSmooth:return Me}}getValueSize(){return this.values.length/this.times.length}shift(e){if(e!==0){let t=this.times;for(let n=0,r=t.length;n!==r;++n)t[n]+=e}return this}scale(e){if(e!==1){let t=this.times;for(let n=0,r=t.length;n!==r;++n)t[n]*=e}return this}trim(e,t){let n=this.times,r=n.length,i=0,a=r-1;for(;i!==r&&n[i]<e;)++i;for(;a!==-1&&n[a]>t;)--a;if(++a,i!==0||a!==r){i>=a&&(a=Math.max(a,1),i=a-1);let e=this.getValueSize();this.times=n.slice(i,a),this.values=this.values.slice(i*e,a*e)}return this}validate(){let e=!0,t=this.getValueSize();t-Math.floor(t)!==0&&(console.error(`THREE.KeyframeTrack: Invalid value size in track.`,this),e=!1);let n=this.times,r=this.values,i=n.length;i===0&&(console.error(`THREE.KeyframeTrack: Track is empty.`,this),e=!1);let a=null;for(let t=0;t!==i;t++){let r=n[t];if(typeof r==`number`&&isNaN(r)){console.error(`THREE.KeyframeTrack: Time is not a valid number.`,this,t,r),e=!1;break}if(a!==null&&a>r){console.error(`THREE.KeyframeTrack: Out of order keys.`,this,t,r,a),e=!1;break}a=r}if(r!==void 0&&fl(r))for(let t=0,n=r.length;t!==n;++t){let n=r[t];if(isNaN(n)){console.error(`THREE.KeyframeTrack: Value is not a valid number.`,this,t,n),e=!1;break}}return e}optimize(){let e=this.times.slice(),t=this.values.slice(),n=this.getValueSize(),r=this.getInterpolation()===Me,i=e.length-1,a=1;for(let o=1;o<i;++o){let i=!1,s=e[o];if(s!==e[o+1]&&(o!==1||s!==e[0])){if(r)i=!0;else{let e=o*n,r=e-n,a=e+n;for(let o=0;o!==n;++o){let n=t[e+o];if(n!==t[r+o]||n!==t[a+o]){i=!0;break}}}}if(i){if(o!==a){e[a]=e[o];let r=o*n,i=a*n;for(let e=0;e!==n;++e)t[i+e]=t[r+e]}++a}}if(i>0){e[a]=e[i];for(let e=i*n,r=a*n,o=0;o!==n;++o)t[r+o]=t[e+o];++a}return a===e.length?(this.times=e,this.values=t):(this.times=e.slice(0,a),this.values=t.slice(0,a*n)),this}clone(){let e=this.times.slice(),t=this.values.slice(),n=this.constructor,r=new n(this.name,e,t);return r.createInterpolant=this.createInterpolant,r}};_l.prototype.TimeBufferType=Float32Array,_l.prototype.ValueBufferType=Float32Array,_l.prototype.DefaultInterpolation=je;var vl=class extends _l{constructor(e,t,n){super(e,t,n)}};vl.prototype.ValueTypeName=`bool`,vl.prototype.ValueBufferType=Array,vl.prototype.DefaultInterpolation=Ae,vl.prototype.InterpolantFactoryMethodLinear=void 0,vl.prototype.InterpolantFactoryMethodSmooth=void 0;var yl=class extends _l{};yl.prototype.ValueTypeName=`color`;var bl=class extends _l{};bl.prototype.ValueTypeName=`number`;var xl=class extends pl{constructor(e,t,n,r){super(e,t,n,r)}interpolate_(e,t,n,r){let i=this.resultBuffer,a=this.sampleValues,o=this.valueSize,s=(n-t)/(r-t),c=e*o;for(let e=c+o;c!==e;c+=4)V.slerpFlat(i,0,a,c-o,a,c,s);return i}},Sl=class extends _l{InterpolantFactoryMethodLinear(e){return new xl(this.times,this.values,this.getValueSize(),e)}};Sl.prototype.ValueTypeName=`quaternion`,Sl.prototype.InterpolantFactoryMethodSmooth=void 0;var Cl=class extends _l{constructor(e,t,n){super(e,t,n)}};Cl.prototype.ValueTypeName=`string`,Cl.prototype.ValueBufferType=Array,Cl.prototype.DefaultInterpolation=Ae,Cl.prototype.InterpolantFactoryMethodLinear=void 0,Cl.prototype.InterpolantFactoryMethodSmooth=void 0;var wl=class extends _l{};wl.prototype.ValueTypeName=`vector`;var Tl=class extends Yn{constructor(e,t=1){super(),this.isLight=!0,this.type=`Light`,this.color=new W(e),this.intensity=t}dispose(){}copy(e,t){return super.copy(e,t),this.color.copy(e.color),this.intensity=e.intensity,this}toJSON(e){let t=super.toJSON(e);return t.object.color=this.color.getHex(),t.object.intensity=this.intensity,this.groundColor!==void 0&&(t.object.groundColor=this.groundColor.getHex()),this.distance!==void 0&&(t.object.distance=this.distance),this.angle!==void 0&&(t.object.angle=this.angle),this.decay!==void 0&&(t.object.decay=this.decay),this.penumbra!==void 0&&(t.object.penumbra=this.penumbra),this.shadow!==void 0&&(t.object.shadow=this.shadow.toJSON()),this.target!==void 0&&(t.object.target=this.target.uuid),t}},El=class extends Tl{constructor(e,t,n){super(e,n),this.isHemisphereLight=!0,this.type=`HemisphereLight`,this.position.copy(Yn.DEFAULT_UP),this.updateMatrix(),this.groundColor=new W(t)}copy(e,t){return super.copy(e,t),this.groundColor.copy(e.groundColor),this}},Dl=new U,Ol=new H,kl=new H,Al=class{constructor(e){this.camera=e,this.intensity=1,this.bias=0,this.normalBias=0,this.radius=1,this.blurSamples=8,this.mapSize=new R(512,512),this.map=null,this.mapPass=null,this.matrix=new U,this.autoUpdate=!0,this.needsUpdate=!1,this._frustum=new _i,this._frameExtents=new R(1,1),this._viewportCount=1,this._viewports=[new B(0,0,1,1)]}getViewportCount(){return this._viewportCount}getFrustum(){return this._frustum}updateMatrices(e){let t=this.camera,n=this.matrix;Ol.setFromMatrixPosition(e.matrixWorld),t.position.copy(Ol),kl.setFromMatrixPosition(e.target.matrixWorld),t.lookAt(kl),t.updateMatrixWorld(),Dl.multiplyMatrices(t.projectionMatrix,t.matrixWorldInverse),this._frustum.setFromProjectionMatrix(Dl),n.set(.5,0,0,.5,0,.5,0,.5,0,0,.5,.5,0,0,0,1),n.multiply(Dl)}getViewport(e){return this._viewports[e]}getFrameExtents(){return this._frameExtents}dispose(){this.map&&this.map.dispose(),this.mapPass&&this.mapPass.dispose()}copy(e){return this.camera=e.camera.clone(),this.intensity=e.intensity,this.bias=e.bias,this.radius=e.radius,this.mapSize.copy(e.mapSize),this}clone(){return new this.constructor().copy(this)}toJSON(){let e={};return this.intensity!==1&&(e.intensity=this.intensity),this.bias!==0&&(e.bias=this.bias),this.normalBias!==0&&(e.normalBias=this.normalBias),this.radius!==1&&(e.radius=this.radius),(this.mapSize.x!==512||this.mapSize.y!==512)&&(e.mapSize=this.mapSize.toArray()),e.camera=this.camera.toJSON(!1).object,delete e.camera.matrix,e}},jl=new U,Ml=new H,Nl=new H,Pl=class extends Al{constructor(){super(new ai(90,1,.5,500)),this.isPointLightShadow=!0,this._frameExtents=new R(4,2),this._viewportCount=6,this._viewports=[new B(2,1,1,1),new B(0,1,1,1),new B(3,1,1,1),new B(1,1,1,1),new B(3,0,1,1),new B(1,0,1,1)],this._cubeDirections=[new H(1,0,0),new H(-1,0,0),new H(0,0,1),new H(0,0,-1),new H(0,1,0),new H(0,-1,0)],this._cubeUps=[new H(0,1,0),new H(0,1,0),new H(0,1,0),new H(0,1,0),new H(0,0,1),new H(0,0,-1)]}updateMatrices(e,t=0){let n=this.camera,r=this.matrix,i=e.distance||n.far;i!==n.far&&(n.far=i,n.updateProjectionMatrix()),Ml.setFromMatrixPosition(e.matrixWorld),n.position.copy(Ml),Nl.copy(n.position),Nl.add(this._cubeDirections[t]),n.up.copy(this._cubeUps[t]),n.lookAt(Nl),n.updateMatrixWorld(),r.makeTranslation(-Ml.x,-Ml.y,-Ml.z),jl.multiplyMatrices(n.projectionMatrix,n.matrixWorldInverse),this._frustum.setFromProjectionMatrix(jl)}},Fl=class extends Tl{constructor(e,t,n=0,r=2){super(e,t),this.isPointLight=!0,this.type=`PointLight`,this.distance=n,this.decay=r,this.shadow=new Pl}get power(){return this.intensity*4*Math.PI}set power(e){this.intensity=e/(4*Math.PI)}dispose(){this.shadow.dispose()}copy(e,t){return super.copy(e,t),this.distance=e.distance,this.decay=e.decay,this.shadow=e.shadow.clone(),this}},Il=class extends Al{constructor(){super(new ji(-5,5,5,-5,.5,500)),this.isDirectionalLightShadow=!0}},Ll=class extends Tl{constructor(e,t){super(e,t),this.isDirectionalLight=!0,this.type=`DirectionalLight`,this.position.copy(Yn.DEFAULT_UP),this.updateMatrix(),this.target=new Yn,this.shadow=new Il}dispose(){this.shadow.dispose()}copy(e){return super.copy(e),this.target=e.target.clone(),this.shadow=e.shadow.clone(),this}},Rl=class{constructor(e=!0){this.autoStart=e,this.startTime=0,this.oldTime=0,this.elapsedTime=0,this.running=!1}start(){this.startTime=zl(),this.oldTime=this.startTime,this.elapsedTime=0,this.running=!0}stop(){this.getElapsedTime(),this.running=!1,this.autoStart=!1}getElapsedTime(){return this.getDelta(),this.elapsedTime}getDelta(){let e=0;if(this.autoStart&&!this.running)return this.start(),0;if(this.running){let t=zl();e=(t-this.oldTime)/1e3,this.oldTime=t,this.elapsedTime+=e}return e}};function zl(){return performance.now()}var Bl=`\\[\\]\\.:\\/`,Vl=RegExp(`[\\[\\]\\.:\\/]`,`g`),Hl=`[^\\[\\]\\.:\\/]`,Ul=`[^`+Bl.replace(`\\.`,``)+`]`,Wl=`((?:WC+[\\/:])*)`.replace(`WC`,Hl),Gl=`(WCOD+)?`.replace(`WCOD`,Ul),Kl=`(?:\\.(WC+)(?:\\[(.+)\\])?)?`.replace(`WC`,Hl),ql=`\\.(WC+)(?:\\[(.+)\\])?`.replace(`WC`,Hl),Jl=RegExp(`^`+Wl+Gl+Kl+ql+`$`),Yl=[`material`,`materials`,`bones`,`map`],Xl=class{constructor(e,t,n){let r=n||Zl.parseTrackName(t);this._targetGroup=e,this._bindings=e.subscribe_(t,r)}getValue(e,t){this.bind();let n=this._targetGroup.nCachedObjects_,r=this._bindings[n];r!==void 0&&r.getValue(e,t)}setValue(e,t){let n=this._bindings;for(let r=this._targetGroup.nCachedObjects_,i=n.length;r!==i;++r)n[r].setValue(e,t)}bind(){let e=this._bindings;for(let t=this._targetGroup.nCachedObjects_,n=e.length;t!==n;++t)e[t].bind()}unbind(){let e=this._bindings;for(let t=this._targetGroup.nCachedObjects_,n=e.length;t!==n;++t)e[t].unbind()}},Zl=class e{constructor(t,n,r){this.path=n,this.parsedPath=r||e.parseTrackName(n),this.node=e.findNode(t,this.parsedPath.nodeName),this.rootNode=t,this.getValue=this._getValue_unbound,this.setValue=this._setValue_unbound}static create(t,n,r){return t&&t.isAnimationObjectGroup?new e.Composite(t,n,r):new e(t,n,r)}static sanitizeNodeName(e){return e.replace(/\s/g,`_`).replace(Vl,``)}static parseTrackName(e){let t=Jl.exec(e);if(t===null)throw Error(`PropertyBinding: Cannot parse trackName: `+e);let n={nodeName:t[2],objectName:t[3],objectIndex:t[4],propertyName:t[5],propertyIndex:t[6]},r=n.nodeName&&n.nodeName.lastIndexOf(`.`);if(r!==void 0&&r!==-1){let e=n.nodeName.substring(r+1);Yl.indexOf(e)!==-1&&(n.nodeName=n.nodeName.substring(0,r),n.objectName=e)}if(n.propertyName===null||n.propertyName.length===0)throw Error(`PropertyBinding: can not parse propertyName from trackName: `+e);return n}static findNode(e,t){if(t===void 0||t===``||t===`.`||t===-1||t===e.name||t===e.uuid)return e;if(e.skeleton){let n=e.skeleton.getBoneByName(t);if(n!==void 0)return n}if(e.children){let n=function(e){for(let r=0;r<e.length;r++){let i=e[r];if(i.name===t||i.uuid===t)return i;let a=n(i.children);if(a)return a}return null},r=n(e.children);if(r)return r}return null}_getValue_unavailable(){}_setValue_unavailable(){}_getValue_direct(e,t){e[t]=this.targetObject[this.propertyName]}_getValue_array(e,t){let n=this.resolvedProperty;for(let r=0,i=n.length;r!==i;++r)e[t++]=n[r]}_getValue_arrayElement(e,t){e[t]=this.resolvedProperty[this.propertyIndex]}_getValue_toArray(e,t){this.resolvedProperty.toArray(e,t)}_setValue_direct(e,t){this.targetObject[this.propertyName]=e[t]}_setValue_direct_setNeedsUpdate(e,t){this.targetObject[this.propertyName]=e[t],this.targetObject.needsUpdate=!0}_setValue_direct_setMatrixWorldNeedsUpdate(e,t){this.targetObject[this.propertyName]=e[t],this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_array(e,t){let n=this.resolvedProperty;for(let r=0,i=n.length;r!==i;++r)n[r]=e[t++]}_setValue_array_setNeedsUpdate(e,t){let n=this.resolvedProperty;for(let r=0,i=n.length;r!==i;++r)n[r]=e[t++];this.targetObject.needsUpdate=!0}_setValue_array_setMatrixWorldNeedsUpdate(e,t){let n=this.resolvedProperty;for(let r=0,i=n.length;r!==i;++r)n[r]=e[t++];this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_arrayElement(e,t){this.resolvedProperty[this.propertyIndex]=e[t]}_setValue_arrayElement_setNeedsUpdate(e,t){this.resolvedProperty[this.propertyIndex]=e[t],this.targetObject.needsUpdate=!0}_setValue_arrayElement_setMatrixWorldNeedsUpdate(e,t){this.resolvedProperty[this.propertyIndex]=e[t],this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_fromArray(e,t){this.resolvedProperty.fromArray(e,t)}_setValue_fromArray_setNeedsUpdate(e,t){this.resolvedProperty.fromArray(e,t),this.targetObject.needsUpdate=!0}_setValue_fromArray_setMatrixWorldNeedsUpdate(e,t){this.resolvedProperty.fromArray(e,t),this.targetObject.matrixWorldNeedsUpdate=!0}_getValue_unbound(e,t){this.bind(),this.getValue(e,t)}_setValue_unbound(e,t){this.bind(),this.setValue(e,t)}bind(){let t=this.node,n=this.parsedPath,r=n.objectName,i=n.propertyName,a=n.propertyIndex;if(t||(t=e.findNode(this.rootNode,n.nodeName),this.node=t),this.getValue=this._getValue_unavailable,this.setValue=this._setValue_unavailable,!t){console.warn(`THREE.PropertyBinding: No target node found for track: `+this.path+`.`);return}if(r){let e=n.objectIndex;switch(r){case`materials`:if(!t.material){console.error(`THREE.PropertyBinding: Can not bind to material as node does not have a material.`,this);return}if(!t.material.materials){console.error(`THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.`,this);return}t=t.material.materials;break;case`bones`:if(!t.skeleton){console.error(`THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.`,this);return}t=t.skeleton.bones;for(let n=0;n<t.length;n++)if(t[n].name===e){e=n;break}break;case`map`:if(`map`in t){t=t.map;break}if(!t.material){console.error(`THREE.PropertyBinding: Can not bind to material as node does not have a material.`,this);return}if(!t.material.map){console.error(`THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.`,this);return}t=t.material.map;break;default:if(t[r]===void 0){console.error(`THREE.PropertyBinding: Can not bind to objectName of node undefined.`,this);return}t=t[r]}if(e!==void 0){if(t[e]===void 0){console.error(`THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.`,this,t);return}t=t[e]}}let o=t[i];if(o===void 0){let e=n.nodeName;console.error(`THREE.PropertyBinding: Trying to update property for track: `+e+`.`+i+` but it wasn't found.`,t);return}let s=this.Versioning.None;this.targetObject=t,t.needsUpdate===void 0?t.matrixWorldNeedsUpdate!==void 0&&(s=this.Versioning.MatrixWorldNeedsUpdate):s=this.Versioning.NeedsUpdate;let c=this.BindingType.Direct;if(a!==void 0){if(i===`morphTargetInfluences`){if(!t.geometry){console.error(`THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.`,this);return}if(!t.geometry.morphAttributes){console.error(`THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.`,this);return}t.morphTargetDictionary[a]!==void 0&&(a=t.morphTargetDictionary[a])}c=this.BindingType.ArrayElement,this.resolvedProperty=o,this.propertyIndex=a}else o.fromArray!==void 0&&o.toArray!==void 0?(c=this.BindingType.HasFromToArray,this.resolvedProperty=o):Array.isArray(o)?(c=this.BindingType.EntireArray,this.resolvedProperty=o):this.propertyName=i;this.getValue=this.GetterByBindingType[c],this.setValue=this.SetterByBindingTypeAndVersioning[c][s]}unbind(){this.node=null,this.getValue=this._getValue_unbound,this.setValue=this._setValue_unbound}};Zl.Composite=Xl,Zl.prototype.BindingType={Direct:0,EntireArray:1,ArrayElement:2,HasFromToArray:3},Zl.prototype.Versioning={None:0,NeedsUpdate:1,MatrixWorldNeedsUpdate:2},Zl.prototype.GetterByBindingType=[Zl.prototype._getValue_direct,Zl.prototype._getValue_array,Zl.prototype._getValue_arrayElement,Zl.prototype._getValue_toArray],Zl.prototype.SetterByBindingTypeAndVersioning=[[Zl.prototype._setValue_direct,Zl.prototype._setValue_direct_setNeedsUpdate,Zl.prototype._setValue_direct_setMatrixWorldNeedsUpdate],[Zl.prototype._setValue_array,Zl.prototype._setValue_array_setNeedsUpdate,Zl.prototype._setValue_array_setMatrixWorldNeedsUpdate],[Zl.prototype._setValue_arrayElement,Zl.prototype._setValue_arrayElement_setNeedsUpdate,Zl.prototype._setValue_arrayElement_setMatrixWorldNeedsUpdate],[Zl.prototype._setValue_fromArray,Zl.prototype._setValue_fromArray_setNeedsUpdate,Zl.prototype._setValue_fromArray_setMatrixWorldNeedsUpdate]];var Ql=class{constructor(e=1,t=0,n=0){return this.radius=e,this.phi=t,this.theta=n,this}set(e,t,n){return this.radius=e,this.phi=t,this.theta=n,this}copy(e){return this.radius=e.radius,this.phi=e.phi,this.theta=e.theta,this}makeSafe(){let e=1e-6;return this.phi=Math.max(e,Math.min(Math.PI-e,this.phi)),this}setFromVector3(e){return this.setFromCartesianCoords(e.x,e.y,e.z)}setFromCartesianCoords(e,t,n){return this.radius=Math.sqrt(e*e+t*t+n*n),this.radius===0?(this.theta=0,this.phi=0):(this.theta=Math.atan2(e,n),this.phi=Math.acos(Ze(t/this.radius,-1,1))),this}clone(){return new this.constructor().copy(this)}},$l=class extends yc{constructor(e=10,t=10,n=4473924,r=8947848){n=new W(n),r=new W(r);let i=t/2,a=e/t,o=e/2,s=[],c=[];for(let e=0,l=0,u=-o;e<=t;e++,u+=a){s.push(-o,0,u,o,0,u),s.push(u,0,-o,u,0,o);let t=e===i?n:r;t.toArray(c,l),l+=3,t.toArray(c,l),l+=3,t.toArray(c,l),l+=3,t.toArray(c,l),l+=3}let l=new jr;l.setAttribute(`position`,new Cr(s,3)),l.setAttribute(`color`,new Cr(c,3));let u=new sc({vertexColors:!0,toneMapped:!1});super(l,u),this.type=`GridHelper`}dispose(){this.geometry.dispose(),this.material.dispose()}},eu=class extends yc{constructor(e=1){let t=[0,0,0,e,0,0,0,0,0,0,e,0,0,0,0,0,0,e],n=[1,0,0,1,.6,0,0,1,0,.6,1,0,0,0,1,0,.6,1],r=new jr;r.setAttribute(`position`,new Cr(t,3)),r.setAttribute(`color`,new Cr(n,3));let i=new sc({vertexColors:!0,toneMapped:!1});super(r,i),this.type=`AxesHelper`}setColors(e,t,n){let r=new W,i=this.geometry.attributes.color.array;return r.set(e),r.toArray(i,0),r.toArray(i,3),r.set(t),r.toArray(i,6),r.toArray(i,9),r.set(n),r.toArray(i,12),r.toArray(i,15),this.geometry.attributes.color.needsUpdate=!0,this}dispose(){this.geometry.dispose(),this.material.dispose()}},tu=class extends Ge{constructor(e,t=null){super(),this.object=e,this.domElement=t,this.enabled=!0,this.state=-1,this.keys={},this.mouseButtons={LEFT:null,MIDDLE:null,RIGHT:null},this.touches={ONE:null,TWO:null}}connect(){}disconnect(){}dispose(){}update(){}};typeof __THREE_DEVTOOLS__<`u`&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent(`register`,{detail:{revision:`170`}})),typeof window<`u`&&(window.__THREE__?console.warn(`WARNING: Multiple instances of Three.js being imported.`):window.__THREE__=`170`);var nu=new Set([`Keys`,`Cols`,`Frms`,`VDrw`,`VIdx`,`VEmt`,`VNum`,`Clip`]),ru=new TextDecoder(`latin1`);function iu(e){let t=Array.from(e).reverse();return ru.decode(new Uint8Array(t)).replace(/\0/g,``)}function au(e){return e===0||e===32||e>=48&&e<=57||e>=65&&e<=90||e>=97&&e<=122}function ou(e,t,n){if(n-t<8)return!1;let r=new DataView(e.buffer,e.byteOffset,e.byteLength),i=t;for(;i<n;){if(i+8>n)return!1;let t=0;for(let n=0;n<4;n++){let r=e[i+n]??0;if(!au(r))return!1;r!==0&&r!==32&&t++}if(t===0)return!1;let a=r.getUint32(i+4,!0),o=i+8+su(a);if(i+8+a>n)return!1;i=Math.min(o,n)}return i===n}function su(e){return e+3&-4}function cu(e,t=0,n=e.length){let r=new DataView(e.buffer,e.byteOffset,e.byteLength),i=[],a=t;for(;a+8<=n;){let t=iu(e.subarray(a,a+4)),o=r.getUint32(a+4,!0);if(a+8+o>n)throw Error(`avfx: block ${t} at 0x${a.toString(16)} overruns its parent`);let s=e.subarray(a+8,a+8+o),c=!nu.has(t)&&ou(e,a+8,a+8+o);i.push({tag:t,offset:a,data:s,children:c?cu(e,a+8,a+8+o):null}),a+=8+su(o)}return i}function lu(e){return new DataView(e.data.buffer,e.data.byteOffset,e.data.byteLength)}function uu(e){return e.data.length>=4?lu(e).getUint32(0,!0):e.data.length>=2?lu(e).getUint16(0,!0):e.data[0]??0}function du(e){return e.data.length>=4?lu(e).getInt32(0,!0):uu(e)}function fu(e){return e.data.length>=4?lu(e).getFloat32(0,!0):0}function pu(e){let t=e.data.indexOf(0);return ru.decode(t>=0?e.data.subarray(0,t):e.data)}function mu(e){if(e.children||e.data.length<2)return!1;let t=0;for(;t<e.data.length&&e.data[t]!==0;t++){let n=e.data[t]??0;if(n<32||n>126)return!1}if(t<2)return!1;for(;t<e.data.length;t++)if(e.data[t]!==0)return!1;return!0}function q(e,t){return e?.children?.find(e=>e.tag===t)}function hu(e,t){return e?.children?.filter(e=>e.tag===t)??[]}function gu(e){let t=e[e.length-1];return!t?.children||e.length===0?[]:_u(t.children)}function _u(e){let t=e[0]?.tag,n=[];for(let r of e)(r.tag===t||!n.length)&&n.push([]),n[n.length-1].push(r);return n}function vu(e,t,n=[]){for(let r of e){let e=[...n,r.tag];t(r,e),r.children&&vu(r.children,t,e)}}var yu=class e{bytes;source;root;constructor(e,t=``){this.bytes=e,this.source=t;let n=cu(e).find(e=>e.tag===`AVFX`);if(!n?.children)throw Error(`avfx: ${t||`file`} has no AVFX root block`);this.root=n}static fromBuffer(t,n=``){return new e(t instanceof Uint8Array?t:new Uint8Array(t),n)}int(e){let t=q(this.root,e);return t?uu(t):void 0}float(e){let t=q(this.root,e);return t?fu(t):void 0}get version(){return this.int(`Ver`)??0}get counts(){return{schedulers:this.int(`ScCn`)??0,timelines:this.int(`TlCn`)??0,emitters:this.int(`EmCn`)??0,particles:this.int(`PrCn`)??0,effectors:this.int(`EfCn`)??0,binders:this.int(`BdCn`)??0,textures:this.int(`TxCn`)??0,models:this.int(`MdCn`)??0}}get scheduler(){return q(this.root,`Schd`)}get timelines(){return hu(this.root,`TmLn`)}get emitters(){return hu(this.root,`Emit`)}get particles(){return hu(this.root,`Ptcl`)}get effectors(){return hu(this.root,`Efct`)}get binders(){return hu(this.root,`Bind`)}get textures(){return hu(this.root,`Tex`).map(pu)}get models(){return hu(this.root,`Modl`).map((e,t)=>{let n=q(e,`VDrw`),r=q(e,`VIdx`);return{index:t,vertexCount:n?Math.floor(n.data.length/36):0,indexCount:r?Math.floor(r.data.length/2):0,block:e}})}get resourcePaths(){let e=new Set;return vu(this.root.children??[],t=>{if(mu(t)){let n=pu(t);/^[\w./-]+\.[a-z0-9]{2,5}$/i.test(n)&&n.includes(`/`)&&e.add(n)}}),[...e]}};function bu(e,t=``){return yu.fromBuffer(e,t)}var J={uiDdsAsIcon:!0,velocityPerFrame:!0,gravityDown:!1,gravityRandom:!0,airResistanceIsSpeedScale:!0,overrideLifeScalesCurves:!0,injectionAngleRotatesParticle:!0,injectionAnglePerCreation:!0,injectionAngleChildEmitters:!0,billboardModelKeepsEmitterRotation:!0,billboardAxisYScreenParallel:!0,childEmitterItemProps:!0,openTimelineItemHoldsEmitter:!0,uvRotationReversed:!0,screenCopy:!0,emitterMotion:!0,emitterGravityNegativeDown:!0,injectionAngleTurnsPosition:!0,simpleVelocityPerSecond:!1,colorToAlphaSharp:!1,infiniteParticlesOnce:!1,modelFresnelColor:!0,lineColorAlongLength:!0,lineLengthAtMin:!0,emitterCreatesOnce:!0,loopingEmittersRepeat:!0,heldParticlesOnce:!0,createTimeZeroMakesOne:!0,zeroCountItemOnce:!1,emitterPeriodicCurvesIgnoreLoop:!0,spriteRevisedScale:!0,initialPositionOnly:!0,initialVelocityCasterTwice:!0,rotationOrderIsApplyOrder:!0,withOptionsFollow:!0,textureDistortion:!0,distortionHalfRange:!0,distortionKeepsFootprint:!0,effectorEndsWithEmitter:!0,radialBlurDisplaySpace:!0,radialBlurRadiusMask:!0,radialBlurGradation:!0,particleDirectionalLight:!0,simpleGroundSprites:!1,simpleVelocityFlattery:!0,simpleFlatteryIgnoresRate:!0,simpleFlatteryKeepsGravity:!0,polygonAsQuad:!0,textureLessTc1White:!0,tc1OffNoAlpha:!0,blendBeforeClamp:!0,addBeforeClamp:!0,coordComputeOrder:!0,moveDirectionAxisZ:!0,coneEmitter:!0,coneModelRings:!0,injectionSpeedRandomPerEmitter:!0,coneSizes:!0,shapeAngles:!0,ringStartZ:!0,modelSkinOnCharacter:!0,dissolveOnCharacter:!0,softParticles:!0,cylinderPointFrame:!0,polylineAxisOrderY:!0,polylineAxisFromRotationBase:!0,polylineWidthScaled:!1,polylineWidthAxis:`xy`,polylineInEffectSpace:!1,carrierEmittersLive:!0,decalNoMipmaps:!0,paletteAlpha:!0,paletteChannels:!0,createTimeRepeats:!0,createOnceIgnoresEmitterCount:!0,createIntervalWholeFrame:!0,sphereOnVertexInward:!1,injectionSpeedRevised:!0,followPositionInEmitterSpace:!0,localFlightRotationAtSpawn:!1,withOptionsRotationAtEmitterStart:!1,shapePointRotationNow:!0,localFlightUnscaled:!0,moveDirectionStreaks:!0,moveDirectionFromFlight:!1,cylinderModelNoInjection:!1,cylinderTangentFlight:!1,moveDirectionKeepsRotation:!0,moveDirectionSpin:!1,emitterRandomScope:`emitter`,rotationVelocityTurnsFlight:`angle`,rotationVelocityFrame:`launch`,itemStartFrame:!0,startFrameNullUpdate:!0,lifeRandomType:!0,rotationVelocityRandom:!0,birthAtCreationTime:!0,emitterVelocityRandom:!1,emitterInjectionAngle:`emitterZ`,emitterVelocityAngle:`flight`,parameterLink:!0,simpleBindModelPath:!0,simpleAreaOnVertices:!0,simpleClockRate:1.2,simpleLifeInfinite:!0,simpleDirectionUp:!0,modelToVertexFromCentre:!0,binderFollowTargetOrientation:!0,inheritBinderRotation:!0,influenceUnknownFollows:!0,inheritParentVelocity:!0,inheritParentLife:!0,createTimeLast:!0,localDirectionFollowsNormal:!0,localDirectionChildEmitters:!0,killTargetsTimelines:!0,binderLinearPath:!0,splineRingRadiusPlane:!0,polylineConnectTarget:!0,collisionFreeze:!0,angleFade:!0,drawLayerOverScene:!0,discUFromOuterEdge:!1,softFadeRangeFromHeader:!0,softUsesDepthOffset:!0,softQuadratic:!0,brightnessScalesAlpha:!1,textureAddByAlpha:!1,textureAddAlphaOnlyNoColor:!0,a8BlackRgb:!0,textureFileMips:!0,textureFilterOtherLayers:!0,cullingD3DWinding:!0,loopKeepsParticles:!1,treeBillboardQuadFixed:!0,tc1MultiplyLuminance:!0,tc1MultiplyIgnoresColor:!0,emitterCameraBillboardAxisY:!0,emitterMoveDirection:!0,textureCalcColor5None:!0,decalProjection:!0},xu=(()=>{let e=new Uint32Array(256);for(let t=0;t<256;t++){let n=t;for(let e=0;e<8;e++)n=n&1?3988292384^n>>>1:n>>>1;e[t]=n>>>0}return e})();function Su(e){let t=4294967295;for(let n=0;n<e.length;n++)t=(xu[(t^e.charCodeAt(n))&255]??0)^t>>>8;return(t^4294967295)>>>0}function Cu(e){return`~`+(~Su(e.toLowerCase())>>>0).toString(16).padStart(8,`0`)}function wu(e){return e.trim().replace(/\\/g,`/`).replace(/^\/+/,``).toLowerCase()}function Tu(e){let t=wu(e),n=t.lastIndexOf(`/`),r=[t,(n>=0?t.slice(0,n+1):``)+Cu(t.slice(n+1))],i=J.uiDdsAsIcon?/^ui\/dds\/(\d+)\/(\d+\.tex)$/.exec(t):null;return i&&r.push(`ui/icon/${i[1]}/${i[2]}`,`ui/icon/${i[1]}/en/${i[2]}`),r}var Eu=class{base;cache=new Map;constructor(e){this.base=e}load(e){let t=wu(e),n=this.cache.get(t);return n||(n=this.fetchFirst(Tu(t)),this.cache.set(t,n)),n}forget(e){for(let t of e)this.cache.delete(wu(t))}async fetchFirst(e){for(let t of e){let e=await fetch(this.base.replace(/\/$/,``)+`/`+t);if(e.ok)return new Uint8Array(await e.arrayBuffer())}return null}},Du={L8:4400,A8:4401,B4G4R4A4:5184,B5G5R5A1:5185,B8G8R8A8:5200,B8G8R8X8:5201,BC1:13344,BC2:13360,BC3:13361,BC4:24864,BC5:25136,BC7:25650},Ou=80;function ku(e){for(let[t,n]of Object.entries(Du))if(n===e)return t;return`0x${e.toString(16).padStart(4,`0`)}`}function Au(e){if(e.length<Ou)throw Error(`tex: file too small (${e.length} bytes)`);let t=new DataView(e.buffer,e.byteOffset,e.byteLength),n=t.getUint32(4,!0),r={format:n,formatName:ku(n),width:t.getUint16(8,!0),height:t.getUint16(10,!0),depth:t.getUint16(12,!0),mipLevels:(e[14]??0)&127,surface:t.getUint32(28,!0)};if(!r.width||!r.height)throw Error(`tex: zero size ${r.width}x${r.height}`);if(r.surface<Ou||r.surface>e.length)throw Error(`tex: bad surface offset 0x${r.surface.toString(16)}`);return r}function ju(e){let t=e.width+3>>2,n=e.height+3>>2,r=e.width*e.height;switch(e.format){case Du.BC1:case Du.BC4:return t*n*8;case Du.BC2:case Du.BC3:case Du.BC5:case Du.BC7:return t*n*16;case Du.L8:case Du.A8:return r;case Du.B4G4R4A4:case Du.B5G5R5A1:return r*2;case Du.B8G8R8A8:case Du.B8G8R8X8:return r*4}return 0}function Mu(e){return Pu(e,Au(e))}function Nu(e){let t=Au(e),n=new DataView(e.buffer,e.byteOffset,e.byteLength),r=[];for(let i=1;i<Math.min(t.mipLevels,13);i++){let a=n.getUint32(28+i*4,!0),o={...t,width:Math.max(1,t.width>>i),height:Math.max(1,t.height>>i),surface:a};if(a<Ou||a+ju(o)>e.length)break;let s=Pu(e,o);r.push({width:s.width,height:s.height,rgba:s.rgba})}return r}function Pu(e,t){let n=ju(t);if(!n)throw Error(`tex: unsupported format ${t.formatName}`);let r=e.subarray(t.surface);if(r.length<n)throw Error(`tex: ${t.formatName} ${t.width}x${t.height} needs ${n} bytes, have ${r.length}`);let i=new Uint8Array(t.width*t.height*4);switch(t.format){case Du.BC1:Fu(i,t.width,t.height,r,8,(e,t,n)=>Bu(e,t,n,!0));break;case Du.BC2:Fu(i,t.width,t.height,r,16,Hu);break;case Du.BC3:Fu(i,t.width,t.height,r,16,Uu);break;case Du.BC4:Fu(i,t.width,t.height,r,8,Wu);break;case Du.BC5:Fu(i,t.width,t.height,r,16,Gu);break;case Du.BC7:Fu(i,t.width,t.height,r,16,ed);break;default:Ku(i,t,r)}return{...t,rgba:i}}function Fu(e,t,n,r,i,a){let o=t+3>>2,s=n+3>>2,c=new Uint8Array(64);for(let l=0;l<s;l++)for(let s=0;s<o;s++){a(r,(l*o+s)*i,c);for(let r=0;r<4;r++){let i=l*4+r;if(i>=n)break;for(let n=0;n<4;n++){let a=s*4+n;if(a>=t)break;e.set(c.subarray((r*4+n)*4,(r*4+n)*4+4),(i*t+a)*4)}}}}var Iu=e=>e<<3|e>>2,Lu=e=>e<<2|e>>4;function Ru(e,t){return(e[t]??0)|(e[t+1]??0)<<8}function zu(e,t){return(Ru(e,t)|Ru(e,t+2)<<16)>>>0}function Bu(e,t,n,r){let i=Ru(e,t),a=Ru(e,t+2),o=new Uint8Array(16),s=(e,t)=>{o[t*4]=Iu(e>>11),o[t*4+1]=Lu(e>>5&63),o[t*4+2]=Iu(e&31),o[t*4+3]=255};s(i,0),s(a,1);for(let e=0;e<3;e++){let t=o[e]??0,n=o[4+e]??0;i>a||!r?(o[8+e]=Math.floor((2*t+n+1)/3),o[12+e]=Math.floor((t+2*n+1)/3)):(o[8+e]=t+n+1>>1,o[12+e]=0)}o[11]=255,o[15]=i>a||!r?255:0;let c=zu(e,t+4);for(let e=0;e<16;e++){let t=c>>>2*e&3;n.set(o.subarray(t*4,t*4+4),e*4)}}function Vu(e,t,n,r){let i=e[t]??0,a=e[t+1]??0,o=[i,a,0,0,0,0,0,0];if(i>a)for(let e=1;e<=6;e++)o[e+1]=Math.floor(((7-e)*i+e*a+3)/7);else{for(let e=1;e<=4;e++)o[e+1]=Math.floor(((5-e)*i+e*a+2)/5);o[6]=0,o[7]=255}let s=(e[t+2]??0)|(e[t+3]??0)<<8|(e[t+4]??0)<<16,c=(e[t+5]??0)|(e[t+6]??0)<<8|(e[t+7]??0)<<16;for(let e=0;e<16;e++){let t=e<8?s>>3*e&7:c>>3*(e-8)&7;n[e*4+r]=o[t]??0}}function Hu(e,t,n){Bu(e,t+8,n,!1);for(let r=0;r<16;r++){let i=e[t+(r>>1)]??0;n[r*4+3]=((r&1?i>>4:i)&15)*17}}function Uu(e,t,n){Bu(e,t+8,n,!1),Vu(e,t,n,3)}function Wu(e,t,n){Vu(e,t,n,0);for(let e=0;e<16;e++){let t=n[e*4]??0;n[e*4+1]=t,n[e*4+2]=t,n[e*4+3]=255}}function Gu(e,t,n){Vu(e,t,n,0),Vu(e,t+8,n,1);for(let e=0;e<16;e++)n[e*4+2]=0,n[e*4+3]=255}function Ku(e,t,n){let r=t.width*t.height;for(let i=0;i<r;i++){let r=0,a=0,o=0,s=255;switch(t.format){case Du.L8:r=a=o=n[i]??0;break;case Du.A8:r=a=o=255,s=n[i]??0;break;case Du.B4G4R4A4:{let e=Ru(n,i*2);o=(e&15)*17,a=(e>>4&15)*17,r=(e>>8&15)*17,s=(e>>12&15)*17;break}case Du.B5G5R5A1:{let e=Ru(n,i*2);o=Iu(e&31),a=Iu(e>>5&31),r=Iu(e>>10&31),s=e>>15?255:0;break}case Du.B8G8R8A8:case Du.B8G8R8X8:o=n[i*4]??0,a=n[i*4+1]??0,r=n[i*4+2]??0,s=t.format===Du.B8G8R8X8?255:n[i*4+3]??0}e[i*4]=r,e[i*4+1]=a,e[i*4+2]=o,e[i*4+3]=s}}var qu=[[3,4,0,0,4,0,1,0,3,0],[2,6,0,0,6,0,0,1,3,0],[3,6,0,0,5,0,0,0,2,0],[2,6,0,0,7,0,1,0,2,0],[1,0,2,1,5,6,0,0,2,3],[1,0,2,0,7,8,0,0,2,2],[1,0,0,0,7,7,1,0,4,0],[2,6,0,0,5,5,1,0,2,0]],Ju=[52428,34952,61166,60616,51328,65260,65224,60544,51200,65516,65152,59392,65512,65280,65520,61440,63248,142,28928,2254,140,29456,12544,36046,2188,12560,26214,13932,6120,4080,29070,14748,43690,61680,23130,13260,15420,21930,38550,42330,29646,5064,12876,15324,27030,49980,39270,1632,626,1252,20032,10016,51510,37740,14790,25500,37686,40134,33150,59160,52464,4044,30532,60962],Yu=[2858963024,1784303680,1515864576,1414570152,2779054080,2694860880,1431675040,1515868240,2857697280,2857719040,2863289600,2425393296,2492765332,2762253476,2846200912,705315408,2777960512,172118100,2779096320,1436590240,2829603924,1785348160,2762231808,437912832,5285028,2862977168,342452500,1768494080,2693105056,2860651540,1352967248,1784283648,2846195712,1351655592,2829094992,606348324,11162880,613566756,608801316,1352993360,1342874960,2863285316,1717960704,2778768800,1352683680,1764256040,1152035396,1717986816,2856600644,1420317864,2508232064,2526451200,2824098984,2157286784,2853442580,2526412800,2863272980,2689618080,2695210400,2516582400,1082146944,2846402984,2863311428,709513812],Xu=[15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,2,8,2,2,8,8,15,2,8,2,2,8,8,2,2,15,15,6,8,2,8,15,15,2,8,2,2,2,15,15,6,6,2,6,8,15,15,2,2,15,15,15,15,15,2,2,15],Zu=[3,3,15,15,8,3,15,15,8,8,6,6,6,5,3,3,3,3,8,15,3,3,6,10,5,8,8,6,8,5,15,15,8,15,3,5,6,10,8,15,15,3,15,5,15,15,15,15,3,15,5,5,5,8,5,10,5,10,8,13,15,12,3,3],Qu=[15,8,8,3,15,15,3,8,15,15,15,15,15,15,15,8,15,8,15,3,15,8,15,8,3,15,6,10,15,15,10,8,15,3,15,10,10,8,9,10,6,15,8,15,3,6,6,8,15,3,15,15,15,15,15,15,15,15,15,15,3,15,15,8],$u={2:[0,21,43,64],3:[0,9,18,27,37,46,55,64],4:[0,4,9,13,17,21,26,30,34,38,43,47,51,55,60,64]};function ed(e,t,n){let r=0,i=n=>{let i=0;for(let a=0;a<n;a++,r++)i|=((e[t+(r>>3)]??0)>>(r&7)&1)<<a;return i},a=-1;for(let e=0;e<8;e++)if(i(1)){a=e;break}if(a<0){n.fill(0);return}let[o=1,s=0,c=0,l=0,u=0,d=0,f=0,p=0,m=2,h=0]=qu[a]??[],g=i(s),_=i(c),v=i(l),y=o*2,b=Array.from({length:y},()=>[0,0,0,0]);for(let e=0;e<3;e++)for(let t=0;t<y;t++)b[t][e]=i(u);if(d)for(let e=0;e<y;e++)b[e][3]=i(d);let x=u,S=d;if(f){for(let e=0;e<y;e++){let t=i(1);for(let n=0;n<4;n++)b[e][n]=b[e][n]<<1|t}x++,S&&S++}else if(p){for(let e=0;e<o;e++){let t=i(1);for(let n of[e*2,e*2+1])for(let e=0;e<4;e++)b[n][e]=b[n][e]<<1|t}x++}let C=(e,t)=>(e<<=8-t,(e|e>>t)&255),w=b.map(e=>[C(e[0],x),C(e[1],x),C(e[2],x),S?C(e[3],S):255]),T=e=>o===2?(Ju[g]??0)>>e&1:o===3?(Yu[g]??0)>>>2*e&3:0,E=e=>e===0||o===2&&e===Xu[g]||o===3&&(e===Zu[g]||e===Qu[g]),D=[];for(let e=0;e<16;e++)D.push(i(E(e)?m-1:m));let O=[];if(h)for(let e=0;e<16;e++)O.push(i(e===0?h-1:h));let k=(e,t,n)=>(64-n)*e+n*t+32>>6;for(let e=0;e<16;e++){let t=T(e),r=w[t*2],i=w[t*2+1],a=$u[m][D[e]],o=a;h&&(v===0?o=$u[h][O[e]]:a=$u[h][O[e]]);let s=[k(r[0],i[0],a),k(r[1],i[1],a),k(r[2],i[2],a),k(r[3],i[3],o)];_===1?[s[0],s[3]]=[s[3],s[0]]:_===2?[s[1],s[3]]=[s[3],s[1]]:_===3&&([s[2],s[3]]=[s[3],s[2]]),n.set(s,e*4)}}function td(e,t){let n=q(e,t);return n?du(n):0}async function nd(e,t){let n=[],r=e.counts,i=[];for(let[n,r]of e.textures.entries()){let e={index:n,path:r,hashedPath:Tu(r)[1]??r,found:!1};if(t)try{let n=await t.load(r);if(n){e.found=!0;let t=Au(n);e.format=t.formatName,e.width=t.width,e.height=t.height}}catch(t){e.error=String(t)}i.push(e)}let a=new Set(e.textures),o=e.resourcePaths.filter(e=>!a.has(e)),s=e.scheduler,c=gu(hu(s,`Item`)).map(e=>{let t={children:e};return{enabled:td(t,`bEna`)!==0,start:td(t,`StTm`),timeline:td(t,`TlNo`)}}),l=e.timelines.map((e,t)=>({index:t,items:td(e,`TICn`),clips:td(e,`CpCn`)})),u=e.emitters.map((e,t)=>{let n=q(e,`SdNm`);return{index:t,type:td(e,`EVT`),particles:td(e,`PrCn`),emitters:td(e,`EmCn`),...n&&n.data.length>1?{sound:new TextDecoder().decode(n.data).replace(/\0.*$/s,``)}:{}}}),d=e.particles.map((e,t)=>({index:t,type:td(e,`PrVT`),uvSets:td(e,`UvSN`),textureNodes:(e.children??[]).filter(e=>/^(TC[1-4]|TN|TR|TD|TP)$/.test(e.tag)).map(e=>e.tag)})),f=e.binders.map((e,t)=>({index:t,type:td(e,`BnVr`)})),p=e.effectors.map((e,t)=>({index:t,type:td(e,`EfVT`)}));r.textures!==i.length&&n.push(`TxCn=${r.textures} but ${i.length} Tex blocks`),r.emitters!==u.length&&n.push(`EmCn=${r.emitters} but ${u.length} Emit blocks`),r.particles!==d.length&&n.push(`PrCn=${r.particles} but ${d.length} Ptcl blocks`);let m=i.filter(e=>e.error).length,h=i.filter(e=>t&&!e.found&&!e.error).length;return h&&n.push(`${h} texture(s) not found (neither by name nor by name hash)`),m&&n.push(`${m} texture(s): request failed — is the dev server running?`),{source:e.source,version:e.version,counts:r,textures:i,otherResources:o,models:e.models.map(e=>({index:e.index,vertices:e.vertexCount,indices:e.indexCount})),scheduler:{items:c,triggers:gu(hu(s,`Trgr`)).length},timelines:l,emitters:u,particles:d,binders:f,effectors:p,warnings:n}}function rd(e){let t=Math.max(1,e.width>>1),n=Math.max(1,e.height>>1),r=e.width/t,i=e.height/n,a=new Uint8Array(t*n*4);for(let o=0;o<n;o++)for(let n=0;n<t;n++){let s=0,c=0,l=0,u=0;for(let t=0;t<i;t++)for(let a=0;a<r;a++){let d=((o*i+t)*e.width+n*r+a)*4,f=e.rgba[d+3];s+=e.rgba[d]*f,c+=e.rgba[d+1]*f,l+=e.rgba[d+2]*f,u+=f}let d=(o*t+n)*4;a[d]=u?Math.round(s/u):0,a[d+1]=u?Math.round(c/u):0,a[d+2]=u?Math.round(l/u):0,a[d+3]=Math.round(u/(r*i))}return{width:t,height:n,rgba:a}}function id(e,t=[]){let n=J.a8BlackRgb&&e.format===Du.A8,i=e=>{if(!n)return e;let t=e.slice();for(let e=0;e<t.length;e+=4)t[e]=t[e+1]=t[e+2]=0;return t},a=new Zs(i(e.rgba),e.width,e.height,E,f);if(a.wrapS=a.wrapT=r,a.magFilter=l,a.minFilter=d,J.textureFileMips&&t.length){let n=[{width:e.width,height:e.height,rgba:e.rgba},...t];for(;n.at(-1).width>1||n.at(-1).height>1;)n.push(rd(n.at(-1)));a.mipmaps=n.map(e=>({data:i(e.rgba),width:e.width,height:e.height})),a.generateMipmaps=!1}else a.generateMipmaps=!0;return a.anisotropy=1,a.colorSpace=``,a.userData.alphaOnly=e.format===Du.A8,a.needsUpdate=!0,a}var ad=class{resolver;cache=new Map;constructor(e){this.resolver=e}get(e){let t=this.cache.get(e);return t||(t=this.resolver.load(e).then(e=>e?id(Mu(e),J.textureFileMips?Nu(e):[]):null),this.cache.set(e,t)),t}forget(e){let t=new Set(e.map(wu));for(let[e,n]of this.cache)t.has(wu(e))&&(n.then(e=>e?.dispose()),this.cache.delete(e))}dispose(){for(let e of this.cache.values())e.then(e=>e?.dispose());this.cache.clear()}},Y={Parameter:0,Powder:1,Windmill:2,Line:3,Laser:4,Model:5,Polyline:6,Reserve0:7,Quad:8,Polygon:9,Decal:10,DecalRing:11,Disc:12,LightModel:13,ModelSkin:14,Dissolve:15},od={Point:0,Cone:1,ConeModel:2,SphereModel:3,CylinderModel:4,Model:5},sd={Blend:0,Multiply:1,Add:2,Subtract:3,Screen:4,Reverse:5,Min:6,Max:7,Opacity:8,UnknownMultiply9:9,UnknownAdd10:10,UnknownSubtract11:11,UnknownScreen12:12};function cd(e){return e>=9&&e<=12?e-8:e}var ld={X:0,Y:1,Z:2,MoveDirection:3,BillboardAxisY:4,ScreenBillboard:5,CameraBillboard:6,MoveDirectionBillboard:7,CameraBillboardAxisY:8,TreeBillboard:9,None:10},ud={RandomToVertex:0,OrderToVertex:1,RandomOnVertex:2,OrderOnVertex:3,RandomToVertexWithoutSingularPoint:4,OrderToVertexWithoutSingularPoint:5,RandomOnVertexWithoutSingularPoint:6,OrderOnVertexWithoutSingularPoint:7},dd={Spline:0,Linear:1,Step:2},fd={Const:0,Repeat:1,Add:2,None:-1},pd={FirstPlusMinus:0,FirstPlus:1,FirstMinus:2,AlwaysPlusMinus:3,AlwaysPlus:4,AlwaysMinus:5},md={None:0,X_YZ:1,X_Y:2,X_Z:3,Y_XZ:4,Y_X:5,Y_Z:6,Z_XY:7,Z_X:8,Z_Y:9},hd={InitialPosition:0,InitialPosition_WithOptions:1,AllAlways:2,AllInitial:3,AllAlways_NoPosition:4,AllInitial_NoPosition:5,None:6,WithOptions_NoPosition:7,Unknown:8,Unknown_NoPosition:9},gd={None:0,Front:1,Back:2,Double:3},_d={Repeat:0,Clamp:1,Mirror:2},vd={Caster:0,Target:1},yd={PointLight:0,DirectionalLight:1,Reserve2:2,ChromaticAberration:3,GaussianBlur:4,DirectionalBlur:5,CameraQuake_Variable:6,RadialBlur:7,BlackHole:8,CameraQuake:9},bd={Origin:0,FitGround:1,DamageCircle:2,ByName:3},xd={0:`(null)`,1:`Face (j_kao)`,3:`Base of weapon (relative)`,4:`Center of weapon`,5:`Tip of weapon (relative)`,6:`Right shoulder`,7:`Left shoulder`,8:`Right forearm`,9:`Left forearm`,10:`Right calves`,11:`Left calves`,16:`Front of character`,25:`Top of head`,26:`Middle of head`,27:`Front of head`,28:`Chest (j_sebo_c)`,29:`Center of character (n_root)`,30:`Center of character (n_hara)`,31:`Waist (j_kosi)`,32:`Right hand (j_te_r)`,33:`Left hand (j_te_l)`,34:`Right foot`,35:`Left foot`,42:`Above character (n_root)`,43:`Head (near right eye)`,44:`Head (near left eye)`,71:`Character origin (n_root)`,77:`Right hand (n_buki_r)`,78:`Left hand (n_buki_l)`,107:`n_throw`},Sd=e=>xd[e]??`unknown`,X=(e,t,n=0)=>{let r=q(e,t);return r?du(r):n},Cd=(e,t,n=0)=>{let r=q(e,t);return r?fu(r):n},Z=(e,t)=>X(e,t)!==0,wd=e=>({tag:`rec`,offset:0,data:new Uint8Array,children:e});function Q(e,t=!1){if(!e?.children)return;let n=q(e,`Keys`),r=[];if(n){let e=new DataView(n.data.buffer,n.data.byteOffset,n.data.byteLength);for(let t=0;t+16<=n.data.length;t+=16)r.push({time:e.getInt16(t,!0),type:e.getInt16(t+2,!0),x:e.getFloat32(t+4,!0),y:e.getFloat32(t+8,!0),z:e.getFloat32(t+12,!0)})}if(r.length){for(let e=1;e<r.length;e++)r[e].time<r[e-1].time&&(r[e].time+=65536);return r.sort((e,t)=>e.time-t.time),{keys:r,pre:X(e,`BvPr`),post:X(e,`BvPo`),random:X(e,`RanT`),color:t}}}function Td(e){return{x:Q(q(e,`X`)),y:Q(q(e,`Y`)),z:Q(q(e,`Z`)),rx:Q(q(e,`XR`)),ry:Q(q(e,`YR`)),rz:Q(q(e,`ZR`)),connect:X(e,`ACT`),connectRandom:X(e,`ACTR`)}}function Ed(e){let t=Td(e),n=e=>e===1?md.X_YZ:e===2?md.Y_X:e;return{...t,connect:n(t.connect),connectRandom:n(t.connectRandom)}}function Dd(e){return{rgb:Q(q(e,`RGB`),!0),a:Q(q(e,`A`)),sclR:Q(q(e,`SclR`)),sclG:Q(q(e,`SclG`)),sclB:Q(q(e,`SclB`)),sclA:Q(q(e,`SclA`)),bri:Q(q(e,`Bri`)),ranR:Q(q(e,`RanR`)),ranG:Q(q(e,`RanG`)),ranB:Q(q(e,`RanB`)),ranA:Q(q(e,`RanA`)),ranBri:Q(q(e,`RBri`))}}function Od(e){return e?e.children?{value:Cd(e,`Val`,-1),random:Cd(e,`ValR`),randomType:X(e,`Type`)}:{value:du(e),random:0,randomType:0}:{value:-1,random:0,randomType:0}}function kd(e){return{enabled:Z(e,`bEnb`),target:X(e,`TgtB`),localDirection:X(e,`LoDr`),createTime:X(e,`CrTm`),createCount:X(e,`CrCn`,1),probability:X(e,`CrPr`,100),influenceCoord:X(e,`PICd`),influenceColor:X(e,`PICo`),inheritScale:Z(e,`ICbS`),inheritRotation:Z(e,`ICbR`),inheritPosition:Z(e,`ICbP`),inheritBinderRotation:Z(e,`ICbB`),inheritParentVelocity:Z(e,`IPbV`),inheritParentLife:Z(e,`IPbL`),overrideLife:Z(e,`bOvr`),overrideLifeValue:X(e,`OvrV`),overrideLifeRandom:X(e,`OvrR`),startFrame:X(e,`StFr`),startFrameNullUpdate:Z(e,`bStN`),generateDelay:X(e,`GenD`),generateDelayByOne:Z(e,`bGD`),injectionAngle:[Cd(e,`BIAX`),Cd(e,`BIAY`),Cd(e,`BIAZ`)],parameterLink:X(e,`PrLk`,-1)}}function Ad(e){if(!e?.children)return;let t=[],n=q(e,`TLst`);if(n)for(let e of n.data)t.push(e);let r=q(e,`TxNo`);return r&&t.unshift(du(r)),{enabled:Z(e,`bEna`),colorToAlpha:Z(e,`bC2A`),uvSet:X(e,`UvSN`),borderU:X(e,`TBUT`),borderV:X(e,`TBVT`),calcColor:X(e,`TCCT`),calcAlpha:X(e,`TCAT`),filter:X(e,`TFT`,1),screenCopy:Z(e,`bUSC`),textures:t.filter(e=>e>=0),texN:Q(q(e,`TxN`)),texNRandom:Q(q(e,`TxNR`))}}function jd(e){if(e?.children)return{enabled:Z(e,`bEna`),border:X(e,`TBT`),texture:X(e,`TxNo`,-1),offset:Q(q(e,`POff`)),offsetRandom:Q(q(e,`POfR`))}}function Md(e){let t=Ad(e);if(t&&e)return{...t,targets:[Z(e,`bT1`),Z(e,`bT2`),Z(e,`bT3`),Z(e,`bT4`)],power:Q(q(e,`DPow`))}}function Nd(e){let t=e.scheduler,n=gu(hu(t,`Item`)).map(e=>{let t=wd(e);return{enabled:Z(t,`bEna`),start:X(t,`StTm`),timeline:X(t,`TlNo`)}}),r=e.timelines.map(e=>({loopStart:X(e,`LpSt`),loopEnd:X(e,`LpEd`),binder:X(e,`BnNo`,-1),clipCount:X(e,`CpCn`),items:gu(hu(e,`Item`)).map(e=>{let t=wd(e);return{enabled:Z(t,`bEna`),start:X(t,`StTm`),end:X(t,`EdTm`),binder:X(t,`BdNo`,-1),effector:X(t,`EfNo`,-1),emitter:X(t,`EmNo`,-1),platform:X(t,`Plfm`),clip:X(t,`ClNo`,-1)}}),clips:hu(e,`Clip`).map(Pd)})),i=e.emitters.map((e,t)=>{let n=X(e,`PrCn`),r=gu(hu(e,`ItPr`)).map(e=>kd(wd(e))),i=Rd(hu(e,`ItEm`),n).map(e=>kd(wd(e))),a=q(e,`SdNm`);return{index:t,type:X(e,`EVT`),sound:a?new TextDecoder().decode(a.data).replace(/\0.*$/s,``):``,loopStart:X(e,`LpSt`),loopEnd:X(e,`LpEd`),childLimit:X(e,`ClCn`),rotationBase:X(e,`RBDT`),coordOrder:X(e,`CCOT`),rotationOrder:X(e,`ROT`),life:Od(q(e,`Life`)),createCount:Q(q(e,`CrC`)),createCountRandom:Q(q(e,`CrCR`)),createInterval:Q(q(e,`CrI`)),createIntervalRandom:Q(q(e,`CrIR`)),gravity:Q(q(e,`Gra`)),gravityRandom:Q(q(e,`GraR`)),airResistance:Q(q(e,`ARs`)),airResistanceRandom:Q(q(e,`ARsR`)),velocityRandom:[Q(q(e,`VRX`)),Q(q(e,`VRY`)),Q(q(e,`VRZ`))],anyDirection:Z(e,`bAD`),injectAngles:[Q(q(e,`IAX`)),Q(q(e,`IAY`)),Q(q(e,`IAZ`))],injectAnglesRandom:[Q(q(e,`IAXR`)),Q(q(e,`IAYR`)),Q(q(e,`IAZR`))],effector:X(e,`EfNo`,-1),color:Dd(q(e,`Col`)),position:Td(q(e,`Pos`)),rotation:Td(q(e,`Rot`)),scale:Td(q(e,`Scl`)),particleItems:r.slice(0,n||r.length),emitterItems:i,data:q(e,`Data`),modelIndex:X(q(e,`Data`),`MdNo`,-1),generateMethod:X(q(e,`Data`),`GeMT`),injectionSpeed:Q(q(q(e,`Data`),`IjS`)),injectionSpeedRandom:Q(q(q(e,`Data`),`IjSR`)),divideX:X(q(e,`Data`),`DivX`,1),divideY:X(q(e,`Data`),`DivY`,1),radius:Q(q(q(e,`Data`),`Rad`))??Q(q(q(e,`Data`),`Rads`)),length:Q(q(q(e,`Data`),`Len`)),coneAngles:[Q(q(q(e,`Data`),`AnX`)),Q(q(q(e,`Data`),`AnY`)),Q(q(q(e,`Data`),`AnZ`))],coneAnglesRandom:[Q(q(q(e,`Data`),`AnXR`)),Q(q(q(e,`Data`),`AnYR`)),Q(q(q(e,`Data`),`AnZR`))],coneRotationOrder:X(q(e,`Data`),`ROT`),injectionAngle:Q(q(q(e,`Data`),`IjA`)),injectionAngleRandom:Q(q(q(e,`Data`),`IjAR`)),innerSize:Q(q(q(e,`Data`),`InS`)),outerSize:Q(q(q(e,`Data`),`OuS`)),innerSizeRandom:Q(q(q(e,`Data`),`InSR`)),outerSizeRandom:Q(q(q(e,`Data`),`OuSR`)),radiusRandom:Q(q(q(e,`Data`),`RadR`))}}),a=e.particles.map((e,t)=>{let n=q(e,`Data`);return{index:t,type:X(e,`PrVT`),collision:X(e,`Coll`,-1),loopStart:X(e,`LpSt`),loopEnd:X(e,`LpEd`),rotationBase:X(e,`RBDT`),rotationOrder:X(e,`RoOT`),coordOrder:X(e,`CCOT`),drawMode:X(e,`RMT`),culling:X(e,`CulT`),depthTest:Z(e,`DsDt`),softParticle:Z(e,`DsSp`),depthWrite:Z(e,`DsDw`),depthOffset:Cd(e,`DpOf`),clipNear:Z(e,`bNea`)?[Cd(e,`NeSt`),Cd(e,`NeEd`)]:void 0,clipFar:Z(e,`bFar`)?[Cd(e,`FaSt`),Cd(e,`FaEd`)]:void 0,clipBase:X(e,`FaBP`),drawPriority:X(e,`DwPr`),life:Od(q(e,`Life`)),gravity:Q(q(e,`Gra`)),airResistance:Q(q(e,`ARs`)),airResistanceRandom:Q(q(e,`ARsR`)),gravityRandom:Q(q(e,`GraR`)),scale:Td(q(e,`Scl`)),rotation:Td(q(e,`Rot`)),position:Td(q(e,`Pos`)),rotVelX:Q(q(e,`VRX`)),rotVelY:Q(q(e,`VRY`)),rotVelZ:Q(q(e,`VRZ`)),rotVelXRandom:Q(q(e,`VRXR`)),rotVelYRandom:Q(q(e,`VRYR`)),rotVelZRandom:Q(q(e,`VRZR`)),color:Dd(q(e,`Col`)),uvSets:hu(e,`UvSt`).map(e=>({mode:X(e,`CUvT`),scale:Ed(q(e,`Scl`)),scroll:Ed(q(e,`Scr`)),rotation:Q(q(e,`Rot`)),rotationRandom:Q(q(e,`RotR`))})),tc1:Ad(q(e,`TC1`)),tc2:Ad(q(e,`TC2`)),tc3:Ad(q(e,`TC3`)),tc4:Ad(q(e,`TC4`)),palette:jd(q(e,`TP`)),distortion:Md(q(e,`TD`)),data:n,modelIndex:q(n,`MdNo`)?.data[0]??X(n,`MNO`,-1),lit:X(e,`PrVT`)===Y.Model&&Z(n,`bLgt`),lightType:X(n,`DLT`),colorBegin:q(n,`ColB`)?Dd(q(n,`ColB`)):void 0,colorEnd:q(n,`ColE`)?Dd(q(n,`ColE`)):void 0,lineLength:Q(q(n,`Len`)),lineLengthRandom:Q(q(n,`LenR`)),laserWidth:Q(q(n,`Wdt`)),laserWidthRandom:Q(q(n,`WdtR`)),fresnelType:X(n,`FrsT`),windmillUvType:X(n,`WUvT`),ringWidth:Q(q(n,`WID`)),ringWidthRandom:Q(q(n,`WIDR`)),ringFan:Cd(n,`RF`,1),fresnelCurve:Q(q(n,`FrC`)),auraTarget:X(n,`AuTT`),dissolve:X(e,`PrVT`)===Y.Dissolve?{target:X(n,`DTT`),reverse:Z(n,`bRev`),erosion:Q(q(n,`EroR`)),endWidth:Q(q(n,`EdW`)),midWidth:Q(q(n,`EdCW`)),startWidth:Q(q(n,`ECMP`)),intensity:Q(q(n,`Int`)),shape:X(n,`BST`),startColor:Dd(q(q(n,`EdC`),`StrC`)),midColor:Dd(q(q(n,`EdC`),`MidC`)),endColor:Dd(q(q(n,`EdC`),`EndC`)),edgeScale:Dd(q(n,`EdC`))}:void 0,simple:Z(e,`bSCt`)?Ld(q(e,`Smpl`)):void 0,polyline:X(e,`PrVT`)===Y.Polyline?Fd(n):void 0,disc:X(e,`PrVT`)===Y.Disc?Id(n):void 0}}),o=e.binders.map((e,t)=>{let n=q(e,`PrpS`);return{index:t,type:X(e,`BnVr`),bindPoint:X(n,`BPT`),bindTargetPoint:X(n,`BPTP`),bindPointId:X(n,`BPID`,-1),followTargetOrientation:!q(e,`bFTO`)||Z(e,`bFTO`),distance:Q(q(q(e,`Data`),`Dst`)),goal:q(e,`PrpG`)?.children?.length?{bindPoint:X(q(e,`PrpG`),`BPT`),bindTargetPoint:X(q(e,`PrpG`),`BPTP`),bindPointId:X(q(e,`PrpG`),`BPID`,-1)}:void 0,carryOver:Q(q(q(e,`Data`),`COF`)),spring:Q(q(q(e,`Data`),`SpS`)),updateFrames:X(n,`CoUF`,-1),life:X(e,`Life`,-1),rings:[`Prp1`,`Prp2`].map(t=>q(e,t)).filter(e=>e?.children?.length&&Z(e,`bRng`)).map(e=>({time:X(e,`RnPT`),x:Cd(e,`RnPX`),y:Cd(e,`RnPY`),z:Cd(e,`RnPZ`),radius:Cd(e,`RnRd`)}))}}),s=Rd(hu(t,`Trgr`),n.length).map((e,t)=>{let n=wd(e);return{index:t,enabled:Z(n,`bEna`),start:X(n,`StTm`),timeline:X(n,`TlNo`,-1)}}),c=e.effectors.map((e,t)=>{let n=q(e,`Data`);return{index:t,type:X(e,`EfVT`),loopStart:X(e,`LpSt`),loopEnd:X(e,`LpEd`),rotationOrder:X(e,`RoOT`),color:Dd(q(n,`Col`)),distance:Q(q(n,`DstS`)),attenuation:X(n,`Attn`),position:Td(q(n,`Pos`)),radialBlur:X(e,`EfVT`)===yd.RadialBlur?{length:Q(q(n,`Len`)),strength:Q(q(n,`Str`)),gradation:Q(q(n,`Gra`)),innerRadius:Q(q(n,`IRad`)),outerRadius:Q(q(n,`ORad`))}:void 0,dirLight:X(e,`EfVT`)===yd.DirectionalLight?{ambient:Dd(q(n,`Amb`)),color:Dd(q(n,`Col`)),power:Q(q(n,`Pow`)),rotation:Td(q(n,`Rot`))}:void 0,quake:X(e,`EfVT`)===yd.CameraQuake||X(e,`EfVT`)===yd.CameraQuake_Variable?{attenuation:Q(q(n,`Att`)),radiusIn:Q(q(n,`RdI`)),radiusOut:Q(q(n,`RdO`)),rotation:Td(q(n,`Rot`)),position:Td(q(n,`Pos`))}:void 0}}),l=e.root,u={position:[Cd(l,`RvPx`),Cd(l,`RvPy`),Cd(l,`RvPz`)],rotation:[Cd(l,`RvRx`),Cd(l,`RvRy`),Cd(l,`RvRz`)],scale:[Cd(l,`RvSx`,1),Cd(l,`RvSy`,1),Cd(l,`RvSz`,1)],color:[Cd(l,`RvR`,1),Cd(l,`RvG`,1),Cd(l,`RvB`,1)]},d=q(l,`SPFR`)?Cd(l,`SPFR`):void 0,f=[`X`,`Y`,`Z`].map(e=>({enabled:Z(l,`AF${e}e`),inner:Cd(l,`AF${e}i`),outer:Cd(l,`AF${e}o`)}));return{revised:u,softFadeRange:d,directionalLightSource:X(l,`DLST`),angleFade:f,drawLayer:X(l,`DwLy`,2),scheduler:n,triggers:s,effectors:c,timelines:r,emitters:i,particles:a,binders:o,textures:e.textures}}function Pd(e){let t=new DataView(e.data.buffer,e.data.byteOffset,e.data.byteLength),n=e.data.length>=4?t.getUint32(0,!0):0,r=String.fromCharCode(n>>>24&255,n>>>16&255,n>>>8&255,n&255),i=n=>e.data.length>=8+n*4?t.getInt32(4+n*4,!0):0,a=n=>e.data.length>=24+n*4?t.getFloat32(20+n*4,!0):0;return{type:r,ints:[i(0),i(1),i(2),i(3)],floats:[a(0),a(1),a(2),a(3)]}}function Fd(e){if(!e?.children)return;let t=t=>q(e,t)?Dd(q(e,t)):void 0;return{createType:X(e,`LnCT`),pointCount:X(e,`PnC`,2),pointCountCenter:X(e,`PnCC`),useEdge:Z(e,`bEdg`),notBillboard:Z(e,`bNtB`),notBillboardAxis:X(e,`NBBA`),isLocal:Z(e,`bLcl`),connectTarget:Z(e,`bCtg`),connectReverse:Z(e,`bCtr`),width:Q(q(e,`Wd`)),widthRandom:Q(q(e,`WdR`)),widthBegin:Q(q(e,`WdB`)),widthCenter:Q(q(e,`WdC`)),widthEnd:Q(q(e,`WdE`)),length:Q(q(e,`Len`)),softness:Q(q(e,`Sft`)),colorBegin:t(`ColB`),colorCenter:t(`ColC`),colorEnd:t(`ColE`),colorEdgeBegin:t(`CoEB`),colorEdgeCenter:t(`CoEC`),colorEdgeEnd:t(`CoEE`)}}function Id(e){if(!e?.children)return;let t=t=>Q(q(e,t));return{partsCount:X(e,`PrtC`,1),countU:X(e,`PCnU`,2),countV:X(e,`PCnV`,2),intervalFactor:Cd(e,`PIFU`),angle:t(`Ang`),angleRandom:t(`AngR`),heightBeginInner:t(`HBI`),heightBeginInnerRandom:t(`HBIR`),heightEndInner:t(`HEI`),heightEndInnerRandom:t(`HEIR`),heightBeginOuter:t(`HBO`),heightBeginOuterRandom:t(`HBOR`),heightEndOuter:t(`HEO`),heightEndOuterRandom:t(`HEOR`),widthBegin:t(`WB`),widthBeginRandom:t(`WBR`),widthEnd:t(`WE`),widthEndRandom:t(`WER`),radiusBegin:t(`RB`),radiusBeginRandom:t(`RBR`),radiusEnd:t(`RE`),radiusEndRandom:t(`RER`),colorInner:q(e,`CEI`)?Dd(q(e,`CEI`)):void 0,colorOuter:q(e,`CEO`)?Dd(q(e,`CEO`)):void 0}}function Ld(e){if(!e?.children)return;let t=q(e,`Cols`),n=q(e,`Frms`),r=[];if(t)for(let e=0;e+4<=t.data.length;e+=4)r.push([t.data[e],t.data[e+1],t.data[e+2],t.data[e+3]]);let i=[];if(n){let e=new DataView(n.data.buffer,n.data.byteOffset,n.data.byteLength);for(let t=0;t+2<=n.data.length;t+=2)i.push(e.getInt16(t,!0))}let a=(t,n=0)=>Cd(e,t,n),o=(t,n=0)=>X(e,t,n);return{injectionPosition:o(`SIPT`),injectionModel:o(`IJMN`,-1),bindModel:o(`VBMN`,-1),createNewAfterDeath:(q(e,`bCrN`)?.data[0]??0)!==0,lineLength:[a(`LLin`),a(`LLax`)],injectionDirection:o(`SIDT`),baseDirection:o(`SBDT`),createCount:o(`CCnt`,1),createArea:[a(`CrAX`),a(`CrAY`),a(`CrAZ`)],gravity:[a(`CGX`),a(`CGY`),a(`CGZ`)],scaleStart:[a(`SBX`,1),a(`SBY`,1)],scaleEnd:[a(`SEX`,1),a(`SEY`,1)],scaleCurve:a(`SC`,1),scaleRandomX:[a(`SRX0`,1),a(`SRX1`,1)],scaleRandomY:[a(`SRY0`,1),a(`SRY1`,1)],scaleRandomLink:(q(e,`bSRL`)?.data[0]??0)!==0,uvReverse:(q(e,`bRUV`)?.data[0]??0)!==0,scaleByParent:(q(e,`bSnP`)?.data[0]??0)!==0,bindParent:(q(e,`bBnP`)?.data[0]??255)!==0,flatteryRate:a(`FltR`),flatterySpeed:a(`FltS`),coordAccuracy:[a(`CAX`,1),a(`CAY`,1),a(`CAZ`,1)],rotStart:[a(`RIX`),a(`RIY`),a(`RIZ`)],rotRandom:[a(`RBX`),a(`RBY`),a(`RBZ`)],rotVelocity:[a(`RVX`),a(`RVY`),a(`RVZ`)],rotAdd:[a(`RAX`),a(`RAY`),a(`RAZ`)],radialDirection:[a(`IRD0`),a(`IRD1`)],blockCount:Math.max(1,o(`BlkN`,1)),velocityMin:a(`VMin`),velocityMax:a(`VMax`),uvCellsU:Math.max(1,o(`UvCU`,1)),uvCellsV:Math.max(1,o(`UvCV`,1)),uvInterval:o(`UvIv`,1),uvRandom:o(`UvNR`),uvLoops:o(`UvLC`),pivot:[a(`PvtX`),a(`PvtY`)],interval:o(`CrI`,1),intervalRandom:o(`CrIR`),intervalOnMovement:q(e,`CIM`)?a(`CIM`):void 0,intervalCount:Math.max(1,o(`CrIC`,1)),life:o(`CrIL`,1)<0?-1:Math.max(1,o(`CrIL`,1)),lifeRandom:o(`CrLR`),colors:r,frames:i}}function Rd(e,t){let n=e[e.length-1];return n?.children?_u(n.children).slice(t):[]}function zd(e){let t=e|0;return()=>{t=t+1831565813|0;let e=Math.imul(t^t>>>15,t|1);return e^=e+Math.imul(e^e>>>7,e|61),((e^e>>>14)>>>0)/4294967296}}var Bd=zd(1);function Vd(){return Bd()}function Hd(e,t){let n=Bd;Bd=e;try{return t()}finally{Bd=n}}function Ud(e,t){return typeof t==`number`?t:e.post===fd.Add?t.total:t.t}var Wd=class{values;constructor(e=Vd,t=32){this.values=Array.from({length:t},()=>e())}get(e){return this.values[e%this.values.length]??0}};function Gd(e,t){return t?[e.x,e.y,e.z]:[e.z,e.z,e.z]}function Kd(e,t,n,r){let i=e[t],a=Gd(i,r)[n],o=e[t-1],s=e[t+1];if(o&&!s)return i.y*(a-Gd(o,r)[n]);if(s&&!o)return i.x*(Gd(s,r)[n]-a);let c=s?Gd(s,r)[n]-a:o?a-Gd(o,r)[n]:0,l=o?a-Gd(o,r)[n]:c;return .5*i.y*l+.5*i.x*c}function qd(e,t){return t===void 0?1:2*e/(e+t)}function Jd(e,t,n,r,i){let a=t[n-1],o=t[n],s=Gd(a,e.color),c=Gd(o,e.color),l=o.time-a.time;if(l<=0){i[0]=c[0],i[1]=c[1],i[2]=c[2];return}let u=(r-a.time)/l;if(!e.color&&o.type===dd.Step)u=+(r>=o.time);else if(!(e.color||o.type===dd.Linear)){let r=u,d=r*r,f=d*r,p=2*f-3*d+1,m=f-2*d+r,h=-2*f+3*d,g=f-d,_=t[n-2],v=t[n+1],y=qd(l,_?a.time-_.time:void 0),b=qd(l,v?v.time-o.time:void 0);for(let r=0;r<3;r++){let a=Kd(t,n-1,r,e.color)*y,o=Kd(t,n,r,e.color)*b;i[r]=p*s[r]+m*a+h*c[r]+g*o}return}for(let e=0;e<3;e++)i[e]=s[e]+(c[e]-s[e])*u}function Yd(e,t,n=[0,0,0]){let r=Ud(e,t),i=e.keys,a=i[0],o=i[i.length-1];if(i.length===1){let t=Gd(a,e.color);return n[0]=t[0],n[1]=t[1],n[2]=t[2],n}let s=o.time-a.time,c=0;if(r<a.time&&s>0&&(e.pre===fd.Repeat||e.pre===fd.Add)){let t=o.time-(a.time-r)%s;c=-Math.round((t-r)/s),r=t,e.pre===fd.Repeat&&(c=0)}else r>o.time&&s>0&&(e.post===fd.Repeat||e.post===fd.Add)&&(c=Math.floor((r-a.time)/s),r-=c*s,e.post===fd.Repeat&&(c=0));if(r<=a.time){let t=Gd(a,e.color);n[0]=t[0],n[1]=t[1],n[2]=t[2]}else if(r>=o.time){let t=Gd(o,e.color);n[0]=t[0],n[1]=t[1],n[2]=t[2]}else{let t=1;for(;t<i.length-1&&i[t].time<r;)t++;Jd(e,i,t,r,n)}if(c){let t=Gd(a,e.color),r=Gd(o,e.color);for(let e=0;e<3;e++)n[e]=n[e]+c*(r[e]-t[e])}return n}var Xd=[0,0,0];function $(e,t,n=0){return e?Yd(e,t,Xd)[0]:n}function Zd(e,t,n){if(!e)return 0;let r=e.random;r>=pd.AlwaysPlusMinus&&(n=Vd());let i=$(e,t);switch(r){case pd.FirstPlus:case pd.AlwaysPlus:return i*n;case pd.FirstMinus:case pd.AlwaysMinus:return-i*n;default:return i*(n*2-1)}}function Qd(e,t,n,r,i,a){let[o,s,c]=$d(e.connectRandom,Zd(e.rx,t,r.get(i)),Zd(e.ry,t,r.get(i+1)),Zd(e.rz,t,r.get(i+2))),[l,u,d]=$d(e.connect,$(e.x,t,n),$(e.y,t,n),$(e.z,t,n));return a[0]=l+o,a[1]=u+s,a[2]=d+c,a}function $d(e,t,n,r){switch(e){case md.X_YZ:n=r=t;break;case md.X_Y:n=t;break;case md.X_Z:r=t;break;case md.Y_XZ:t=r=n;break;case md.Y_X:t=n;break;case md.Y_Z:r=n;break;case md.Z_XY:t=n=r;break;case md.Z_X:t=r;break;case md.Z_Y:n=r}return[t,n,r]}function ef(e){let t=e&32768?-1:1,n=e>>10&31,r=e&1023;return n===0?t*r*2**-24:n===31?r?NaN:t*(1/0):t*(1+r/1024)*2**(n-15)}var tf;function nf(){if(!tf){tf=new bi(1,1);let e=tf.getAttribute(`position`),t=tf.getAttribute(`uv`);for(let n=0;n<t.count;n++)t.setXY(n,e.getX(n)/1,-e.getY(n)/1)}return tf}var rf,af;function of(){return af||(af=new Kr(1,1,1),af.userData.decalBox=!0),af}function sf(){if(!rf){rf=nf().clone().rotateX(-Math.PI/2),rf.translate(0,.01,0);let e=rf.getAttribute(`uv`);for(let t=0;t<e.count;t++)e.setY(t,-e.getY(t));for(let t=0;t<e.count;t++)e.setX(t,-e.getX(t))}return rf}var cf=1,lf=128,uf=16;function df(e){let t=lf,n=new Float32Array(6579),r=new Float32Array(4386),i=[],a=2*Math.acos(1-2*Math.max(0,Math.min(1,e))),o=a/(Math.PI*2),s=uf;for(let e=0;e<=t;e++){let n=.5+(e/t-.5)*o;for(let t=0;t<=s;t++)r.set([t/s-.5,n-.5],(e*17+t)*2);if(e<t)for(let t=0;t<s;t++){let n=e*17+t,r=n+s+1;i.push(n,n+1,r,n+1,r+1,r)}}let c=new jr;return c.setAttribute(`position`,new br(n,3)),c.setAttribute(`uv`,new br(r,2)),c.setIndex(i),c.userData.ringAngle=a,c.userData.ringCentred=!0,ff(c,0,cf),c}function ff(e,t,n){let r=Math.max(0,n),i=Math.max(0,Math.min(r,t));if(e.userData.ringInner===i&&e.userData.ringOuter===r)return;e.userData.ringInner=i,e.userData.ringOuter=r;let a=e.getAttribute(`position`),o=e.userData.ringAngle,s=lf,c=e.userData.ringCentred;for(let e=0;e<=s;e++){let t,n;if(c){let r=(e/s-.5)*o;t=Math.sin(r),n=Math.cos(r)}else{let r=e/s*o;t=Math.cos(r),n=-Math.sin(r)}for(let o=0;o<=uf;o++){let s=r+(i-r)*o/uf;a.setXYZ(e*17+o,t*s,.01,n*s)}}a.needsUpdate=!0,e.computeBoundingSphere()}function pf(e,t,n=!0,r=1){let i=Math.max(2,e),a=Math.max(2,t),o=Math.max(1,r),s=i*a,c=new Float32Array(s*o*2),l=[];for(let e=0;e<o;e++)for(let t=0;t<a;t++)for(let r=0;r<i;r++){let o=r/(i-1);if(c.set([(n?o:1-o)-.5,t/(a-1)-.5],(e*s+r+t*i)*2),r<i-1&&t<a-1){let n=e*s+r+t*i,a=n+i;l.push(n,a,n+1,n+1,a,a+1)}}let u=new jr;return u.setAttribute(`position`,new br(new Float32Array(s*o*3),3)),u.setAttribute(`uv`,new br(c,2)),u.setAttribute(`color`,new br(new Float32Array(s*o*4).fill(1),4)),u.setIndex(l),u.userData.disc={nu:i,nv:a,np:o,shape:``,colors:``},u}function mf(e,t){let n=e.userData.disc,r=Object.values(t).join(`,`);if(n.shape===r)return;n.shape=r;let i=e.getAttribute(`position`),a=n.nu*n.nv;for(let e=0;e<n.np;e++)for(let r=0;r<n.nv;r++){let o=r/(n.nv-1),s=o*t.angle+e*2*Math.PI/n.np,c=Math.cos(s),l=-Math.sin(s),u=t.radiusBegin+(t.radiusEnd-t.radiusBegin)*o,d=t.widthBegin+(t.widthEnd-t.widthBegin)*o,f=t.heightBeginInner+(t.heightEndInner-t.heightBeginInner)*o,p=t.heightBeginOuter+(t.heightEndOuter-t.heightBeginOuter)*o;for(let o=0;o<n.nu;o++){let s=o/(n.nu-1),m=1-s,h=4*t.intervalFactor,g=Math.abs(h)<1e-6?m:Math.expm1(h*m)/Math.expm1(h),_=u-d+2*d*g;i.setXYZ(e*a+o+r*n.nu,c*_,p+(f-p)*s,l*_)}}i.needsUpdate=!0,e.computeBoundingSphere()}function hf(e,t,n){let r=e.userData.disc,i=`${t.toArray()},${n.toArray()}`;if(r.colors===i)return;r.colors=i;let a=e.getAttribute(`color`),o=new B;for(let e=0;e<r.nu;e++){o.lerpVectors(n,t,e/(r.nu-1));for(let t=0;t<r.np;t++)for(let n=0;n<r.nv;n++)a.setXYZW(t*r.nu*r.nv+e+n*r.nu,o.x,o.y,o.z,o.w)}a.needsUpdate=!0}function gf(){let e=new jr;return e.setAttribute(`position`,new Cr(new Float32Array(24),3)),e.setAttribute(`uv`,new Cr([-.5,0,0,.5].flatMap(e=>[-.5,e,.5,e]),2)),e.setIndex([0,2,1,1,2,3,2,4,3,3,4,5,4,6,5,5,6,7]),_f(e,1,.5),e}function _f(e,t,n,r=new H(0,0,1)){let i=e.getAttribute(`position`);[[-r.y*n,-r.z*n],[0,0],[0,t],[r.y*n,t+r.z*n]].forEach(([e,t],r)=>{i.setXYZ(r*2,-n,e,t),i.setXYZ(r*2+1,n,e,t)}),i.needsUpdate=!0,e.computeBoundingSphere()}var vf=[];function yf(e=0){let t=+(e===1),n=vf[t];if(!n){let e=[],r=[],i=[],a=1/2,o=[[1,1],[-1,1],[-1,-1],[1,-1]];for(let n=0;n<4;n++){let s=Math.cos(n*Math.PI/2),c=Math.sin(n*Math.PI/2),[l,u]=o[n],d=e.length/3;for(let[n,i]of[[0,0],[a,0],[a,a],[0,a]])t?e.push(l*n,u*i,0):e.push(-(n*s-i*c),n*c+i*s,0),r.push(.5-2*n/1,.5-2*i/1);!t||l*u<0?i.push(d,d+2,d+1,d,d+3,d+2):i.push(d,d+1,d+2,d,d+2,d+3)}n=new jr,n.setAttribute(`position`,new Cr(e,3)),n.setAttribute(`uv`,new Cr(r,2)),n.setIndex(i),vf[t]=n}return n}function bf(e,t){let n=e.models[t];if(!n)return null;let r=q(n.block,`VDrw`),i=q(n.block,`VIdx`);if(!r||!i||n.vertexCount===0)return null;let a=new DataView(r.data.buffer,r.data.byteOffset,r.data.byteLength),o=n.vertexCount,s=new Float32Array(o*3),c=new Float32Array(o*3),l=new Float32Array(o*4),u=new Float32Array(o*2),d=[new Float32Array(o*2),new Float32Array(o*2),new Float32Array(o*2)];for(let e=0;e<o;e++){let t=e*36;for(let n=0;n<3;n++)s[e*3+n]=ef(a.getUint16(t+n*2,!0));for(let n=0;n<3;n++)c[e*3+n]=(a.getUint8(t+8+n)-128)/127;for(let n=0;n<4;n++)l[e*4+n]=a.getUint8(t+16+n)/255;u[e*2]=ef(a.getUint16(t+20,!0)),u[e*2+1]=ef(a.getUint16(t+22,!0));for(let n=0;n<3;n++)d[n][e*2]=ef(a.getUint16(t+24+n*4,!0)),d[n][e*2+1]=ef(a.getUint16(t+26+n*4,!0))}let f=new DataView(i.data.buffer,i.data.byteOffset,i.data.byteLength),p=new Uint16Array(n.indexCount);for(let e=0;e<n.indexCount;e++)p[e]=f.getUint16(e*2,!0);let m=new jr;m.setAttribute(`position`,new br(s,3)),m.setAttribute(`normal`,new br(c,3)),m.setAttribute(`color`,new br(l,4)),m.setAttribute(`uv`,new br(u,2));for(let e=0;e<3;e++)m.setAttribute(`avfxUv${e+2}`,new br(d[e],2));return m.setIndex(new br(p,1)),m.computeBoundingSphere(),m}function xf(e,t){let n=e.models[t],r=n?q(n.block,`VEmt`):void 0;if(!r)return[];let i=new DataView(r.data.buffer,r.data.byteOffset,r.data.byteLength),a=[];for(let e=0;e+28<=r.data.length;e+=28)a.push({position:new H(i.getFloat32(e,!0),i.getFloat32(e+4,!0),i.getFloat32(e+8,!0)),normal:new H(i.getFloat32(e+12,!0),i.getFloat32(e+16,!0),i.getFloat32(e+20,!0))});return a}var Sf=2*Math.PI/1024,Cf=e=>Math.trunc(e/Sf)*Sf,wf=e=>e.life<0?J.simpleLifeInfinite?1/0:1:e.life,Tf=(e,t)=>(1-Math.cos(Math.PI*Math.min(1,Math.max(0,e.flatteryRate+e.flatterySpeed*t))))/2,Ef=1,Df=.012,Of=12.5,kf=(e,t)=>e+(t-e)*Vd();function Af(e,t){return kf(Math.min(e,t),Math.max(e,t))}var jf=class{anim;points;lines;bindPoints;geometry;instanceMatrix;count=0;sprites=[];created=0;nextBurst=0;colorAttr;cellAttr;constructor(e,t,n=[],r=!1,i=[]){this.anim=e,this.points=n,this.lines=r,this.bindPoints=i;let a=Math.min(2048,Math.max(1,e.createCount)),o=t.clone();this.colorAttr=new Qs(new Float32Array(a*4),4),this.cellAttr=new Qs(new Float32Array(a*4),4),o.setAttribute(`spriteColor`,this.colorAttr),o.setAttribute(`spriteCell`,this.cellAttr),this.geometry=o;let s=Math.max(1,a);this.instanceMatrix=new Qs(new Float32Array(s*16),16);let c=new U;for(let e=0;e<s;e++)c.toArray(this.instanceMatrix.array,e*16)}get capacity(){return this.instanceMatrix.count}step(e,t){let n=this.anim,r=e*J.simpleClockRate;for(let t of this.sprites){t.age+=r;let i=J.simpleFlatteryKeepsGravity?t.fall:t.vel;i.x+=n.gravity[0]*e,i.y+=n.gravity[1]*e,i.z+=n.gravity[2]*e;let a=J.simpleFlatteryIgnoresRate?1:n.flatteryRate;if(J.simpleVelocityFlattery&&a>0){let r=t=>Math.max(0,1-a*(1-t)*Of)**+e;t.vel.x*=r(n.coordAccuracy[0]),t.vel.y*=r(n.coordAccuracy[1]),t.vel.z*=r(n.coordAccuracy[2])}t.pos.addScaledVector(t.vel,e).addScaledVector(t.fall,e),t.path&&t.pos.addScaledVector(t.path,Tf(n,t.age)-Tf(n,t.age-r))}if(n.createNewAfterDeath&&t)for(let e of this.sprites)e.age<e.life||(e.age%=e.life,e.pos.copy(e.birth.pos),e.vel.copy(e.birth.vel),e.fall.set(0,0,0),e.path&&e.birth.path&&e.path.copy(e.birth.path),e.world=!1);if(this.sprites=this.sprites.filter(e=>e.age<e.life),!t){this.sprites=[];return}this.nextBurst-=r;let i=n.interval===0?n.createCount:n.intervalCount;for(;this.nextBurst<=0;){for(let e=0;e<i&&(n.createNewAfterDeath||this.created<n.createCount)&&this.sprites.length<this.capacity;e++){let e=this.spawn();e.birth={pos:e.pos.clone(),vel:e.vel.clone(),path:e.path?.clone()},e.age=-this.nextBurst,this.sprites.push(e),this.created++;for(let t=1;t<n.blockCount&&(n.createNewAfterDeath||this.created<n.createCount)&&this.sprites.length<this.capacity;t++)this.sprites.push(this.blockCopy(e,t)),this.created++}this.nextBurst+=n.intervalOnMovement===void 0?Math.max(1,n.interval+Math.floor(Vd()*(n.intervalRandom+1))):1/0}}blockCopy(e,t){let n=this.anim.blockCount;return{...e,pos:e.birth.pos.clone(),vel:e.birth.vel.clone(),fall:new H,path:e.birth.path?.clone(),birth:e.birth,world:!1,rot:e.rot+t*2*Math.PI/n}}get finished(){return this.sprites.length===0}spawn(){let e=this.anim,t=this.created%Math.max(1,this.points.length),n=e.injectionPosition===1&&this.points.length?this.points[t]:void 0,r=n&&this.bindPoints.length?this.bindPoints[t%this.bindPoints.length]:void 0,i=r?r.position.clone().sub(n.position):void 0,a=e.injectionDirection===2?0:e.injectionDirection===3?1:e.injectionDirection===4?2:-1,o=J.simpleDirectionUp&&e.injectionDirection===1,s=kf(Math.min(...e.radialDirection),Math.max(...e.radialDirection)),c=kf(0,2*Math.PI),l=a>=0?new H(+(a===0),+(a===1),+(a===2)):o?new H(Math.sin(s)*Math.cos(c),Math.cos(s),Math.sin(s)*Math.sin(c)):n?n.normal.clone():new H(kf(-1,1),kf(-1,1),kf(-1,1));l.lengthSq()<1e-6&&l.set(0,1,0),l.normalize();let u=kf(Math.min(...e.scaleRandomX),Math.max(...e.scaleRandomX)),d=e.scaleRandomLink?u:kf(Math.min(...e.scaleRandomY),Math.max(...e.scaleRandomY)),f=e.uvCellsU*e.uvCellsV,p=a>=0?new H(kf(-1,1)*e.createArea[0],kf(-1,1)*e.createArea[1],kf(-1,1)*e.createArea[2]):new H(l.x*e.createArea[0],l.y*e.createArea[1],l.z*e.createArea[2]).multiplyScalar(Vd());return{life:Math.min(e.lifeRandom>0?Math.max(1,wf(e)+kf(-1,1)*e.lifeRandom):wf(e),e.uvLoops>0&&e.uvInterval>0&&f>1?e.uvLoops*f*e.uvInterval:1/0),age:0,path:i,pos:n?n.position.clone().addScaledVector(i??n.position,i?Tf(e,0):0).add(J.simpleAreaOnVertices?p:new H):p,vel:l.multiplyScalar(Af(e.velocityMin,e.velocityMax)/(J.simpleVelocityPerSecond?30:1)),fall:new H,scaleX:u,scaleY:d,rot:e.rotStart[2]+kf(-1,1)*e.rotRandom[2],spin:Cf(e.rotAdd[2]+kf(-1,1)*e.rotVelocity[2]),tilt:[e.rotStart[0]+kf(-1,1)*e.rotRandom[0],e.rotStart[1]+kf(-1,1)*e.rotRandom[1]],tiltSpin:[Cf(e.rotAdd[0]+kf(-1,1)*e.rotVelocity[0]),Cf(e.rotAdd[1]+kf(-1,1)*e.rotVelocity[1])],cell:f>1&&e.uvRandom>0?(1+Math.floor(Vd()*Math.min(e.uvRandom,f)))%f:0,flipU:e.uvReverse&&Vd()<.5,lengthK:Vd(),birth:{pos:new H,vel:new H}}}colorAt(e,t){let{colors:n,frames:r}=this.anim;if(!n.length)return t.set(1,1,1,1);let i=0;for(;i<r.length-1&&e>r[i+1];)i++;let a=n[Math.min(i,n.length-1)],o=n[Math.min(i+1,n.length-1)],s=r[i]??0,c=r[i+1]??s,l=c>s?Math.min(1,Math.max(0,(e-s)/(c-s))):0;return t.set((a[0]+(o[0]-a[0])*l)/255,(a[1]+(o[1]-a[1])*l)/255,(a[2]+(o[2]-a[2])*l)/255,(a[3]+(o[3]-a[3])*l)/255)}render(e,t,n,r,i=0,a=1,o=[1,1,1],s=new V){let c=r?r.getWorldPosition(new H):new H,l=new H,u=new z().setFromMatrix4(e),d=this.anim,f=new U,p=new H,m=new V,h=new H,g=new H,_=new V,v=new H(1,0,0),y=new H(0,0,1),b=new H(0,1,0),x=new H,S=new H,C=new H,w=new U,T=new V().setFromAxisAngle(new H(1,0,0),-Math.PI/2),E=d.baseDirection,D=E===1||E===3?new V().setFromAxisAngle(v,-Math.PI/2).premultiply(s):E===2||E===4?s.clone():null,O=J.simpleGroundSprites&&d.injectionDirection===1,k=new B,ee=d.uvCellsU*d.uvCellsV,A=0;for(let r of this.sprites){let s=Math.min(1,r.age/r.life)**+(d.scaleCurve>0?d.scaleCurve:1);!d.bindParent&&!r.world&&(r.pos.applyMatrix4(e),r.vel.applyMatrix3(u),r.fall.applyMatrix3(u),r.path?.applyMatrix3(u),r.world=!0),r.world?p.copy(r.pos):p.copy(r.pos).applyMatrix4(e);let E=J.spriteRevisedScale?o[0]??1:1,te=J.spriteRevisedScale?o[1]??1:1,ne=(d.scaleStart[0]+(d.scaleEnd[0]-d.scaleStart[0])*s)*r.scaleX*(d.scaleByParent?n.x:E)*2,j=(d.scaleStart[1]+(d.scaleEnd[1]-d.scaleStart[1])*s)*r.scaleY*(d.scaleByParent?n.y:te)*2,M=!1;if(this.lines){let e=J.lineLengthAtMin?0:r.lengthK;j=(d.lineLength[0]+(d.lineLength[1]-d.lineLength[0])*e)*a,ne=i>0?Ef*i*p.distanceTo(c):Df,l.copy(r.vel).add(r.fall),r.world||l.applyMatrix3(u),l.lengthSq()>1e-12&&(S.copy(l).normalize(),x.subVectors(c,p).cross(S),x.lengthSq()>1e-12&&(x.normalize(),C.crossVectors(x,S),m.setFromRotationMatrix(w.makeBasis(x,S,C)),M=!0))}O&&(p.y+=.01);let N=r.rot+r.spin*r.age;if(!M){if(O)m.setFromAxisAngle(b,N).multiply(T);else{m.copy(D??t);let e=r.tilt[0]+r.tiltSpin[0]*r.age,n=r.tilt[1]+r.tiltSpin[1]*r.age;n&&m.multiply(_.setFromAxisAngle(b,n)),e&&m.multiply(_.setFromAxisAngle(v,e)),m.multiply(_.setFromAxisAngle(y,N))}}g.set(d.pivot[0]*ne/2,d.pivot[1]*j/2,0).applyQuaternion(m),f.compose(p.add(g),m,h.set(ne,j,1)),f.toArray(this.instanceMatrix.array,A*16),this.colorAt(r.age,k),this.colorAttr.setXYZW(A,k.x,k.y,k.z,k.w);let re=ee>1?(r.cell+(d.uvInterval>0?Math.floor(r.age/d.uvInterval):0))%ee:0,ie=1/d.uvCellsU,ae=1/d.uvCellsV;this.cellAttr.setXYZW(A,(re%d.uvCellsU+ +!!r.flipU)*ie,Math.floor(re/d.uvCellsU)*ae,r.flipU?-ie:ie,ae),A++}this.count=A,this.instanceMatrix.needsUpdate=!0,this.colorAttr.needsUpdate=!0,this.cellAttr.needsUpdate=!0}dispose(){this.geometry.dispose()}},Mf=class{data;geometry=new jr;history=[];points;across;pos;col;uv;historyFrames=20;maxLength=1/0;softness;chain=null;capped=[];chainTime=0;lastTime=0;lastPos=new H;constructor(e){this.data=e,this.points=Math.max(2,e.pointCount),this.across=e.useEdge?3:2;let t=this.points*this.across;this.pos=new Float32Array(t*3),this.col=new Float32Array(t*4),this.uv=new Float32Array(t*2);let n=[];for(let e=0;e<this.points-1;e++)for(let t=0;t<this.across-1;t++){let r=e*this.across+t,i=r+this.across;n.push(r,i,r+1,r+1,i,i+1)}this.geometry.setIndex(n),this.geometry.setAttribute(`position`,new br(this.pos,3)),this.geometry.setAttribute(`color`,new br(this.col,4)),this.geometry.setAttribute(`uv`,new br(this.uv,2)),this.geometry.setDrawRange(0,0)}setPoints(e){this.history=e.map((t,n)=>({time:e.length-1-n,pos:t.clone()})).reverse(),this.historyFrames=Math.max(1,e.length-1)}record(e,t){this.softness===void 0?this.chain=null:this.advanceChain(e,t);let n=this.history[this.history.length-1];if(n&&e<=n.time){n.pos.copy(t);return}this.history.push({time:e,pos:t.clone()});let r=Math.max(1,this.historyFrames);for(;this.history.length>2&&this.history[1].time<=e-r;)this.history.shift()}advanceChain(e,t){let n=this.chain;if(!n){this.chain=Array.from({length:this.points},()=>t.clone()),this.chainTime=this.lastTime=e,this.lastPos.copy(t);return}let r=Math.floor((e-this.chainTime)*2+1e-6),i=Math.min(1,Math.max(0,this.softness)),a=Math.max(1e-6,e-this.lastTime);for(let e=1;e<=r;e++){for(let e=n.length-1;e>0;e--)n[e].lerp(n[e-1],1-i*e/(n.length-1));n[0].copy(this.lastPos).lerp(t,Math.min(1,(this.chainTime+e/2-this.lastTime)/a))}this.chainTime+=r/2,n[0].copy(t),this.lastTime=e,this.lastPos.copy(t)}at(e,t){let n=this.history;if(e<=n[0].time)return t.copy(n[0].pos);for(let r=1;r<n.length;r++){let i=n[r];if(e<=i.time){let a=n[r-1];return t.copy(a.pos).lerp(i.pos,(e-a.time)/Math.max(1e-6,i.time-a.time))}}return t.copy(n[n.length-1].pos)}build(e,t,n,r){let i=this.history;if(i.length<2){this.geometry.setDrawRange(0,0);return}let a=i[i.length-1].time,o=Math.max(i[0].time,a-Math.max(1,this.historyFrames));if(Number.isFinite(this.maxLength)){let e=Math.max(0,this.maxLength);for(let t=i.length-1;t>0&&i[t-1].time>=o-1e-6;t--){let n=i[t].pos.distanceTo(i[t-1].pos);if(n>=e){o=Math.max(o,i[t].time-(i[t].time-i[t-1].time)*(n>0?e/n:0));break}e-=n}}let s=this.chain;if(s&&Number.isFinite(this.maxLength)){let e=this.capped;for(;e.length<s.length;)e.push(new H);let t=Math.max(0,this.maxLength),n=!1;e[0].copy(s[0]);for(let r=1;r<s.length;r++){let i=s[r].distanceTo(s[r-1]);!n&&i<=t?(t-=i,e[r].copy(s[r])):(e[r].copy(e[r-1]),!n&&i>0&&e[r].lerp(s[r],t/i),n=!0)}s=e.slice(0,s.length)}let c=this.points,l=Math.min(1,Math.max(0,this.data.pointCountCenter/(this.points-1))),u=new H,d=new H,f=new H,p=new H,m=new H,h=new H,g=new H,_=new B,v=new B,y=(a-o)/(c-1),b=(e,t,n,r)=>e<=l?t+(n-t)*(l>0?e/l:1):n+(r-n)*((e-l)/Math.max(1e-6,1-l)),x=(e,t,n,r,i)=>e<=l?i.copy(t).lerp(n,l>0?e/l:1):i.copy(n).lerp(r,(e-l)/Math.max(1e-6,1-l)),S=s?s.map((e,t)=>t/(c-1)):null;if(s&&S){let e=0,t=[0];for(let n=1;n<c;n++)t.push(e+=s[n].distanceTo(s[n-1]));if(e>1e-6)for(let n=0;n<c;n++)S[n]=t[n]/e}for(let i=0;i<c;i++){let o=S?S[i]:i/(c-1);if(s)u.copy(s[i]),d.copy(s[Math.min(c-1,i+1)]),f.copy(s[Math.max(0,i-1)]);else{let e=a-y*i;this.at(e,u),this.at(e-Math.max(y,.5),d),this.at(e+Math.max(y,.5),f)}r?h.copy(r):(p.subVectors(f,d),p.lengthSq()<1e-8&&m.lengthSq()>0?p.copy(m):m.copy(p),g.subVectors(e,u),h.crossVectors(g,p),h.lengthSq()<1e-12&&h.set(0,1,0),h.normalize());let l=t.width*b(o,t.begin,t.center,t.end);x(o,n.begin,n.center,n.end,_),x(o,n.edgeBegin,n.edgeCenter,n.edgeEnd,v);for(let e=0;e<this.across;e++){let t=e/(this.across-1),n=i*this.across+e,r=(t-.5)*2*l;this.pos[n*3]=u.x+h.x*r,this.pos[n*3+1]=u.y+h.y*r,this.pos[n*3+2]=u.z+h.z*r;let a=this.data.useEdge&&e!==1?v:_;this.col[n*4]=a.x,this.col[n*4+1]=a.y,this.col[n*4+2]=a.z,this.col[n*4+3]=a.w,this.uv[n*2]=t-.5,this.uv[n*2+1]=o-.5}}for(let e of[`position`,`color`,`uv`])this.geometry.getAttribute(e).needsUpdate=!0;this.geometry.setDrawRange(0,(c-1)*(this.across-1)*6),this.geometry.computeBoundingSphere()}dispose(){this.geometry.dispose()}},Nf=`
  uniform mat3 uvTransform1;
  uniform mat3 uvTransform2;
  uniform mat3 uvTransform3;
  uniform mat3 uvTransform4;
  uniform mat3 uvTransform5;
  // Model UV channel per layer (TC1, TC2, distortion; TC3, TC4): 0 = UV 1, 1..3 = UV 2..4 (MODEL_UVS).
  uniform ivec3 uvChannel;
  uniform ivec2 uvChannel34;
  #ifdef MODEL_UVS
    attribute vec2 avfxUv2;
    attribute vec2 avfxUv3;
    attribute vec2 avfxUv4;
  #endif
  vec2 channelUv(int c) {
    #ifdef MODEL_UVS
      if (c == 1) return avfxUv2;
      if (c == 2) return avfxUv3;
      if (c == 3) return avfxUv4;
    #endif
    return uv;
  }
  uniform float depthOffset;
  #ifdef DECAL_PROJECT
    uniform float decalExtent;
  #endif
  varying vec2 vUv1;
  varying vec2 vUv2;
  varying vec2 vUv3;
  varying vec2 vUv4;
  varying vec2 vUv5;
  #ifdef USE_VERTEX_COLOR
    attribute vec4 color;
    varying vec4 vColor;
  #endif
  #ifdef SPRITES
    // Powder sprite clouds (InstancedMesh): per-sprite colour and atlas cell
    // (offset.xy, size.zw in texture space).
    attribute vec4 spriteColor;
    attribute vec4 spriteCell;
    varying vec4 vSpriteColor;
  #endif
  #ifdef LIT
    varying vec3 vWorldNormal;
    varying vec3 vModelUp;
  #endif
  #ifdef FRESNEL
    varying vec3 vViewNormal;
    varying vec3 vViewPos;
  #endif
  #ifdef LINE_GRADIENT
    varying float vAlong;
  #endif
  #ifdef SOFT
    varying float vViewZ;
  #endif
  void main() {
    // AVFX UVs are centred on 0; transforms apply around the centre, sampling at +0.5.
    vUv1 = (uvTransform1 * vec3(channelUv(uvChannel.x), 1.0)).xy + 0.5;
    vUv2 = (uvTransform2 * vec3(channelUv(uvChannel.y), 1.0)).xy + 0.5;
    vUv3 = (uvTransform3 * vec3(channelUv(uvChannel.z), 1.0)).xy + 0.5;
    vUv4 = (uvTransform4 * vec3(channelUv(uvChannel34.x), 1.0)).xy + 0.5;
    vUv5 = (uvTransform5 * vec3(channelUv(uvChannel34.y), 1.0)).xy + 0.5;
    #ifdef USE_VERTEX_COLOR
      vColor = color;
    #endif
    #ifdef LINE_GRADIENT
      // Streak quads point their +Y end (head) along the motion.
      vAlong = position.y + 0.5;
    #endif
    vec4 local = vec4(position, 1.0);
    #ifdef DECAL_PROJECT
      // The decal's box (unit cube); a DecalRing's reaches out to its outer radius (0.5 + Width).
      local.xz *= decalExtent;
    #endif
    #ifdef SPRITES
      vUv1 = spriteCell.xy + vUv1 * spriteCell.zw;
      vSpriteColor = spriteColor;
      local = instanceMatrix * local;
    #endif
    vec4 mv = modelViewMatrix * local;
    #ifdef FRESNEL
      // The game turns the normal by the model-view matrix itself, scale included (not its inverse transpose):
      // tools/make_test_depth.ts fresnel6, recording 05.20.02 — a flat sphere (X = Z 0.9, Y 0.3) stays light almost to
      // its top and bottom edges, a tall one (0.3 / 0.9) darkens fast up and down; bonfire cone 6f146f5d P2 (X = Z 1.5×Y).
      vViewNormal = mat3(modelViewMatrix) * normal;
      vViewPos = mv.xyz;
    #endif
    #ifdef LIT
      vWorldNormal = mat3(modelMatrix) * normal;
      vModelUp = mat3(modelMatrix) * vec3(0.0, 1.0, 0.0);
    #endif
    gl_Position = projectionMatrix * mv;
    // Depth Offset: the pull in metres, set per frame from the particle's centre (setDepthOffset).
    float pull = depthOffset;
    // Never past the near plane: DpOf 1 in 'view' mode pulls to the eye (w = 0, the particle vanished).
    // Pulled that far it is tested just in front of the camera, i.e. drawn over the scene.
    if (projectionMatrix[2][3] != 0.0) {
      float near = projectionMatrix[3][2] / (projectionMatrix[2][2] - 1.0);
      pull = min(pull, max(0.0, length(mv.xyz) * (1.0 - near * 1.001 / max(-mv.z, 1e-6))));
    }
    #ifdef SOFT
      vViewZ = mv.z;
      #ifdef SOFT_OFFSET
        // Compared with the scene at the depth it is tested at (Depth Offset applied).
        vViewZ = (mv.xyz + normalize(-mv.xyz) * pull).z;
      #endif
    #endif
    // Depth Offset: depth-test as if pulled towards the camera, without moving on screen.
    if (depthOffset != 0.0) {
      vec4 pulled = projectionMatrix * vec4(mv.xyz + normalize(-mv.xyz) * pull, 1.0);
      gl_Position.z = pulled.z / pulled.w * gl_Position.w;
    }
  }
`,Pf=`
  uniform vec4 particleColor;
  uniform sampler2D map1;
  uniform sampler2D map2;
  uniform ivec4 layer1; // enabled, calcColor, calcAlpha, colorToAlpha
  uniform ivec4 layer2;
  uniform sampler2D map4; // TC3
  uniform sampler2D map5; // TC4
  uniform ivec4 layer3;
  uniform ivec4 layer4;
  uniform vec4 layerBias; // mip bias of TC1..TC4 by Texture Filter (filterBias)
  uniform vec4 layerAniso; // maximum anisotropy of TC1..TC4 by Texture Filter (FILTER_ANISOTROPY)
  uniform float distortBias;
  uniform float distortAniso;
  // Texture Distortion (TD): map3 shifts the UVs of the layers flagged in distortLayers (TC1..TC4).
  uniform sampler2D map3;
  uniform ivec4 distortLayers;
  uniform float distortPower;
  // Texture Palette (TP): alpha × palette alpha at u = TC1 alpha + Offset (assumptions.paletteAlpha).
  uniform sampler2D map6;
  uniform float paletteOffset;
  varying vec2 vUv1;
  varying vec2 vUv2;
  varying vec2 vUv3;
  varying vec2 vUv4;
  varying vec2 vUv5;
  #ifdef USE_VERTEX_COLOR
    varying vec4 vColor;
  #endif
  #ifdef SPRITES
    varying vec4 vSpriteColor;
  #endif
  // Color Begin / Color End (model fresnel, line ends); see assumptions.
  uniform vec4 colorBegin;
  uniform vec4 colorEnd;
  uniform float fresnelPower;
  #ifdef SCREEN_COPY
    // TC1 Use Screen Copy (bUSC): the scene without the effect, laid over the particle by its UV (assumptions.screenCopy).
    uniform sampler2D sceneColor;
    uniform vec2 sceneColorSize;
    uniform int screenCopyOn;
    vec3 linearToSrgb(vec3 c) {
      return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(0.0031308, c));
    }
  #endif
  #if defined(SOFT) || defined(DECAL_PROJECT)
    uniform sampler2D sceneDepth;
    uniform vec2 sceneDepthSize;
    uniform vec2 cameraNearFar;
    uniform int softDepthOn;
  #endif
  #ifdef SOFT
    varying float vViewZ;
  #endif
  #ifdef DECAL_PROJECT
    // Decal / DecalRing projected as the game's decal shader does (docs/findings.md «Шейдеры игры»): the scene point
    // under the pixel (scene depth) taken into the decal's unit cube, dropped outside ±0.5, alpha × min(1, 5·(0.5 − |y|)).
    // The UVs the flat stand-in had are computed from that point and go through the layers' UV transforms as before.
    uniform mat4 decalViewToWorld; // the camera's world matrix
    uniform mat4 decalWorldToLocal; // inverse of the decal's world matrix (box: unit cube × scale)
    uniform mat4 decalInverseProjection;
    uniform float decalGround; // the preview's ground plane height (VfxEffect.groundY)
    uniform vec3 decalRing; // inner radius, outer radius, half the fan's arc
    uniform mat3 uvTransform1;
    uniform mat3 uvTransform2;
    uniform mat3 uvTransform3;
    uniform mat3 uvTransform4;
    uniform mat3 uvTransform5;
    vec2 dUv1;
    vec2 dUv2;
    vec2 dUv3;
    vec2 dUv4;
    vec2 dUv5;
    float decalMask;
    void decalProject() {
      vec2 screen = gl_FragCoord.xy / sceneDepthSize;
      float d = texture2D(sceneDepth, screen).x;
      vec4 view = decalInverseProjection * vec4(screen * 2.0 - 1.0, min(d, 0.999999) * 2.0 - 1.0, 1.0);
      vec3 world = (decalViewToWorld * vec4(view.xyz / view.w, 1.0)).xyz;
      bool hit = softDepthOn == 1 && d < 1.0;
      if (!hit) {
        // Nothing in the scene's depth under the pixel (the viewer's floor is off by default): the preview's ground
        // plane takes the place of the game's floor, as the flat stand-in did.
        vec3 eye = (decalViewToWorld * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
        vec3 ray = world - eye;
        float k = abs(ray.y) > 1e-6 ? (decalGround - eye.y) / ray.y : -1.0;
        hit = k > 0.0;
        world = eye + ray * max(k, 0.0);
      }
      vec3 p = (decalWorldToLocal * vec4(world, 1.0)).xyz;
      decalMask = hit ? clamp(5.0 * (0.5 - abs(p.y)), 0.0, 1.0) : 0.0;
      vec2 base;
      #ifdef DECAL_RING
        // As decalRingGeometry: θ from +Z towards +X, u 0 at the outer radius → 1 at the inner one, v = 0.5 + θ / 2π.
        float r = length(p.xz);
        float t = atan(p.x, p.z);
        if (abs(t) > decalRing.z || r < decalRing.x || r > decalRing.y) decalMask = 0.0;
        base = vec2((decalRing.y - r) / max(decalRing.y - decalRing.x, 1e-6) - 0.5, t / 6.2831853);
      #else
        // As decalGeometry: centred UV (−x, −z) — texture top towards +Z, u = 1 towards −X (measured, 12.15.18).
        if (abs(p.x) > 0.5 || abs(p.z) > 0.5) decalMask = 0.0;
        base = vec2(-p.x, -p.z);
      #endif
      dUv1 = (uvTransform1 * vec3(base, 1.0)).xy + 0.5;
      dUv2 = (uvTransform2 * vec3(base, 1.0)).xy + 0.5;
      dUv3 = (uvTransform3 * vec3(base, 1.0)).xy + 0.5;
      dUv4 = (uvTransform4 * vec3(base, 1.0)).xy + 0.5;
      dUv5 = (uvTransform5 * vec3(base, 1.0)).xy + 0.5;
    }
    #define vUv1 dUv1
    #define vUv2 dUv2
    #define vUv3 dUv3
    #define vUv4 dUv4
    #define vUv5 dUv5
  #endif
  #ifdef LIT
    // The effect's own Directional Light (header DLST InLocal): ambient + colour · t (t from N·L by DLT),
    // L towards the light, world space.
    varying vec3 vWorldNormal;
    varying vec3 vModelUp;
    uniform vec3 lightDir;
    uniform vec3 lightAmbient;
    uniform vec3 lightColor;
  #endif
  #ifdef FRESNEL
    varying vec3 vViewNormal;
    varying vec3 vViewPos;
  #endif
  #ifdef LINE_GRADIENT
    varying float vAlong;
  #endif

  // Sampled with the derivatives of the undistorted UV (DISTORT_GRAD, assumptions.distortionKeepsFootprint):
  // a distorted UV jumps between pixels and the jump would pick a tiny mip level.
  vec2 gradX = vec2(0.0);
  vec2 gradY = vec2(0.0);
  // Anisotropic filtering done here, not by the GPU: the browser's (ANGLE → Metal) picked other mips than the game
  // (avfx_test_filter.avfx, preview 02.08.03: past the bias TFT 2 / 3 / 4 dropped 0.56 / 1.06 / 0.55 levels at a
  // footprint of ×3, the game 1.25 / 1.75 / 2.1). The game's rule (material.ts FILTER_ANISOTROPY): the mip by the
  // longer axis of the footprint divided by n = min(its elongation, the maximum); ⌈n⌉ samples along that axis.
  vec4 sampleAniso(sampler2D m, vec2 uv, vec2 gx, vec2 gy, float aniso) {
    vec2 size = vec2(textureSize(m, 0));
    float lx = length(gx * size), ly = length(gy * size);
    vec2 major = lx >= ly ? gx : gy;
    vec2 minor = lx >= ly ? gy : gx;
    float n = clamp(max(lx, ly) / max(min(lx, ly), 1e-6), 1.0, aniso);
    float taps = ceil(n - 1e-3);
    vec4 acc = vec4(0.0);
    for (int i = 0; i < 4; i++) {
      if (float(i) >= taps) break;
      acc += textureGrad(m, uv + major * ((float(i) + 0.5) / taps - 0.5), major / n, minor);
    }
    return acc / taps;
  }
  vec4 filtered(sampler2D m, vec2 uv, vec2 gx, vec2 gy, float bias, float aniso) {
    // The mip bias as a scale of the footprint (textureGrad takes no bias).
    if (aniso > 1.0) return sampleAniso(m, uv, gx * exp2(bias), gy * exp2(bias), aniso);
    return textureGrad(m, uv, gx * exp2(bias), gy * exp2(bias));
  }
  vec4 sampleLayer(sampler2D m, vec2 uv, ivec4 l, float bias, float aniso) {
    #ifdef DISTORT_GRAD
      vec4 t = filtered(m, uv, gradX, gradY, bias, aniso);
    #else
      vec4 t = aniso > 1.0 ? sampleAniso(m, uv, dFdx(uv) * exp2(bias), dFdy(uv) * exp2(bias), aniso) : texture2D(m, uv, bias);
    #endif
    // ColorToAlpha: the texture becomes white with its luminance as alpha (like A8
    // textures). Checked against the game: mon_eisyo01et P9 (red, bC2A) has no dark rim
    // where its mask fades out; keeping the mask's grey as colour drew one. The exact
    // luminance weights are unknown. C2A_SHARP: a rejected threshold experiment.
    if (l.w == 1) {
      float lum = dot(t.rgb, vec3(0.299, 0.587, 0.114));
      #ifdef C2A_SHARP
        float w = max(fwidth(lum), 1e-4);
        lum = clamp((lum - 0.5) / w + 0.5, 0.0, 1.0);
      #endif
      t = vec4(1.0, 1.0, 1.0, lum);
    }
    return t;
  }

  // How a texture layer combines with the layer before it
  // (TextureCalculateColor / TextureCalculateAlpha).
  vec4 combine(vec4 base, vec4 t, ivec4 l) {
    vec3 rgb;
    if (l.y == 9) rgb = base.rgb;
    else
    #ifdef ADD_BY_ALPHA
      // Add: the layer's colour weighted by its own alpha (assumptions.textureAddByAlpha).
      if (l.y == 1) rgb = base.rgb + t.rgb * t.a;
    #else
      if (l.y == 1) rgb = base.rgb + t.rgb;
    #endif
    else if (l.y == 2) rgb = base.rgb - t.rgb;
    else if (l.y == 3) rgb = max(base.rgb, t.rgb);
    else if (l.y == 4) rgb = min(base.rgb, t.rgb);
    else rgb = base.rgb * t.rgb;
    float a;
    if (l.z == 1) a = max(base.a, t.a);
    else if (l.z == 2) a = min(base.a, t.a);
    else if (l.z == 3) a = base.a;
    else a = base.a * t.a;
    return vec4(rgb, a);
  }

  void main() {
    #ifdef DECAL_PROJECT
      decalProject();
    #endif
    // Texture layers combine with each other in order (TC2 onto TC1, then TC3, TC4, each by
    // its own TCCT / TCAT); the result is multiplied by the particle (and vertex) colour.
    vec2 uv1 = vUv1;
    #ifdef DISTORT_GRAD
      vec2 g1x = dFdx(vUv1), g1y = dFdy(vUv1), g2x = dFdx(vUv2), g2y = dFdy(vUv2);
      vec2 g4x = dFdx(vUv4), g4y = dFdy(vUv4), g5x = dFdx(vUv5), g5y = dFdy(vUv5);
    #endif
    vec2 uv2 = vUv2;
    vec2 uv4 = vUv4;
    vec2 uv5 = vUv5;
    #ifdef DISTORTION
      // Offset = (red, green) of the distortion texture centred on 0 (−0.5..0.5, DISTORT_HALF:
      // assumptions.distortionHalfRange) or mapped to −1..1, times Power.
      #ifdef DISTORT_HALF
        vec2 d = (filtered(map3, vUv3, dFdx(vUv3), dFdy(vUv3), distortBias, distortAniso).rg - 0.5) * distortPower;
      #else
        vec2 d = (filtered(map3, vUv3, dFdx(vUv3), dFdy(vUv3), distortBias, distortAniso).rg * 2.0 - 1.0) * distortPower;
      #endif
      if (distortLayers.x == 1) uv1 += d;
      if (distortLayers.y == 1) uv2 += d;
      if (distortLayers.z == 1) uv4 += d;
      if (distortLayers.w == 1) uv5 += d;
    #endif
    vec4 t = vec4(1.0);
    // TC1 enabled without a texture is a white base the other layers combine onto
    // (assumptions.textureLessTc1White).
    #ifdef TC1_WHITE
      bool hasT = true;
      #ifdef TC1_OFF_NO_ALPHA
        // TC1 switched off gives no alpha: only what TC2 brings (assumptions.tc1OffNoAlpha).
        t.a = 0.0;
      #endif
    #else
      bool hasT = false;
    #endif
    #ifdef SCREEN_COPY
      // The whole screen over TC1's UV (0 … 1, distorted with it by TD), not the pixel behind the particle:
      // make_test_screencopy_real.ts chnshift, game 05.47.38 — inside each of four vortices in a row a small upright
      // copy of the caster standing in the middle of the screen, with the pavement around him. v flipped: a texture's
      // top row is v 0, the render target's is v 1. The scene copy is linear (render target); the canvas holds sRGB, as
      // the effect writes it.
      vec2 suv = vec2(uv1.x, 1.0 - uv1.y);
      t = vec4(linearToSrgb(texture2D(sceneColor, suv).rgb), screenCopyOn == 1 ? 1.0 : 0.0);
      hasT = true;
    #endif
    if (layer1.x == 1) {
      #ifdef DISTORT_GRAD
        gradX = g1x; gradY = g1y;
      #endif
      t = sampleLayer(map1, uv1, layer1, layerBias.x, layerAniso.x);
      #ifdef TC1_MULTIPLY_LUMA
        // TC1 with TCCT Multiply (0): the texture's colour enters as its luminance only
        // (assumptions.tc1MultiplyLuminance).
        #ifdef TC1_MULTIPLY_WHITE
          // ...or not at all: the layer leaves the particle colour as it is (assumptions.tc1MultiplyIgnoresColor).
          if (layer1.y == 0) t.rgb = vec3(1.0);
        #else
          if (layer1.y == 0) t.rgb = vec3(dot(t.rgb, vec3(0.299, 0.587, 0.114)));
        #endif
      #endif
      #ifdef PALETTE_CHANNELS
        // Palette: each channel of TC1 + Offset indexes the palette's same channel and replaces TC1
        // (assumptions.paletteChannels).
        vec4 pv = t + paletteOffset;
        t = vec4(texture2D(map6, vec2(pv.r, 0.5)).r, texture2D(map6, vec2(pv.g, 0.5)).g,
                 texture2D(map6, vec2(pv.b, 0.5)).b, texture2D(map6, vec2(pv.a, 0.5)).a);
      #endif
      hasT = true;
    }
    float tc1Alpha = t.a;
    // TC1's Calculate Alpha: 0 (Multiply) leaves the texture's alpha out — alpha = lerp(1, tex.a, k₂) with k₂ 0; 1 / 2 /
    // 3 (Max / Min / None) cut alike by it. Measured: tools/make_test_hud.ts tcat, recording 21.24.18 — alpha_ramp
    // strips on black: TCAT 0 flat 252, TCAT 1 / 2 / 3 the same ramp 5 → 145 → 243, TCAT 0 with the particle's alpha
    // 0.5 flat 145; the layers test (make_test_texture.ts, 18.15.18) the same — solid discs. The palette's index keeps
    // the texture's alpha (not checked with TCAT 0).
    if (layer1.x == 1 && layer1.z == 0) t.a = 1.0;
    if (layer2.x == 1) {
      #ifdef DISTORT_GRAD
        gradX = g2x; gradY = g2y;
      #endif
      vec4 t2 = sampleLayer(map2, uv2, layer2, layerBias.y, layerAniso.y);
      t = hasT ? combine(t, t2, layer2) : t2;
      #ifdef TC1_OFF_NO_ALPHA
        // ...and TC2's alpha Multiply then takes TC2's alpha as it is.
        if (layer2.z == 0) t.a = t2.a;
      #endif
      hasT = true;
    }
    #ifdef DISTORT_GRAD
      gradX = g4x; gradY = g4y;
    #endif
    if (layer3.x == 1) { t = hasT ? combine(t, sampleLayer(map4, uv4, layer3, layerBias.z, layerAniso.z), layer3) : sampleLayer(map4, uv4, layer3, layerBias.z, layerAniso.z); hasT = true; }
    #ifdef DISTORT_GRAD
      gradX = g5x; gradY = g5y;
    #endif
    if (layer4.x == 1) { t = hasT ? combine(t, sampleLayer(map5, uv5, layer4, layerBias.w, layerAniso.w), layer4) : sampleLayer(map5, uv5, layer4, layerBias.w, layerAniso.w); }
    #if defined(PALETTE) && !defined(PALETTE_CHANNELS)
      t.a *= texture2D(map6, vec2(tc1Alpha + paletteOffset, 0.5)).a;
    #endif
    vec4 c = particleColor * t;
    #ifdef LIT
      // DLT 0 Lambert: max(0, N·D); 1 HalfLambert: N·D / 2 + 1/2; 2 Ex: the same with the model's +Y for N
      // (flat over the model). tools/make_test_effector.ts dlight / dlight3, recordings 02.51.25, 04.01.56.
      #if LIT == 1
        float lit = 0.5 * dot(normalize(vWorldNormal), lightDir) + 0.5;
      #elif LIT == 2
        float lit = 0.5 * dot(normalize(vModelUp), lightDir) + 0.5;
      #else
        float lit = max(0.0, dot(normalize(vWorldNormal), lightDir));
      #endif
      // Added to the ambient, not mixed with it: Amb red with Col black left even the HalfLambert ball
      // fully red (recording 02.58.04) — the shader's lerp(C0, C1, t) with C1 = Amb + Col · Pow.
      c.rgb *= lightAmbient + lightColor * lit;
    #endif
    #ifdef USE_VERTEX_COLOR
      c *= vColor;
    #endif
    #ifdef SPRITES
      c *= vSpriteColor;
    #endif
    #ifdef FRESNEL
      // Edge-on (|N·V| = 0) → Color Begin, facing the camera → Color End, Color End weighted |N·V|^FrC. Measured
      // with tools/make_test_depth.ts fresnel (recording 01.46.29, white spheres, ColB black → ColE white): the
      // brightness from the centre to the rim fits |N·V|^e with e 0.90 / 1.84 / 3.84 for FrC 1 / 2 / 4 (rms ≤ 0.008;
      // the preview's own linear spheres measure e 1.06 the same way). The alpha takes the same weight: fresnel3,
      // recording 02.02.52 (ColB alpha 0 → ColE alpha 1, Blend) — game and preview ring profiles agree within 0.03.
      float facing = abs(dot(normalize(vViewNormal), normalize(-vViewPos)));
      c *= mix(colorBegin, colorEnd, pow(facing, fresnelPower));
    #endif
    #ifdef LINE_GRADIENT
      c *= mix(colorEnd, colorBegin, vAlong);
    #endif
    #ifdef SOFT
      // Soft Particle: fade out over SOFT_DISTANCE metres in front of the scene's geometry.
      if (softDepthOn == 1) {
        float d = texture2D(sceneDepth, gl_FragCoord.xy / sceneDepthSize).x;
        float sceneZ = (cameraNearFar.x * cameraNearFar.y) / ((cameraNearFar.y - cameraNearFar.x) * d - cameraNearFar.y);
        float soft = clamp((vViewZ - sceneZ) / SOFT_DISTANCE, 0.0, 1.0);
        #ifdef SOFT_QUADRATIC
          soft *= soft; // assumptions.softQuadratic
        #endif
        c.a *= soft;
      }
    #endif
    #ifdef DECAL_PROJECT
      c.a *= decalMask;
    #endif
    if (c.a <= 0.002) discard;
    vec3 rgb = max(c.rgb, 0.0);
    float a = clamp(c.a, 0.0, 1.0);
    // Blend equations that ignore source alpha get it folded into the colour.
    #if defined(PREMULTIPLY)
      rgb *= a;
    #elif defined(MULTIPLY)
      rgb = mix(vec3(1.0), rgb, a);
    #endif
    // Written as is: effect colours and textures are display values, blended on screen.
    // Checked against the game (mon_eisyo01et): linear blending with sRGB output, with or
    // without ACES/AgX tone mapping, washes P9's rim (colour (2, 0.67, 0.67)) out to pink;
    // writing the value as is keeps it red as in the game. Not affected by the renderer's
    // output colour space or tone mapping (toneMapped = false).
    // Dither by ±½ of an 8-bit step: wide faint glows otherwise show bands.
    rgb += (fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) / 255.0;
    gl_FragColor = vec4(rgb, a);
  }
`;function Ff(e){return e===_d.Clamp?i:e===_d.Mirror?a:r}var If=[1,1,2,3,4],Lf=e=>-.5*(e-1),Rf=(e,t)=>t||J.textureFilterOtherLayers?Math.min(4,Math.max(0,e.filter)):1;function zf(e,t,n=!1,r=1){let i=e.clone();return i.wrapS=Ff(t.borderU),i.wrapT=Ff(t.borderV),r===0&&(i.magFilter=o,i.minFilter=c),n&&(i.minFilter=r===0?o:l,i.generateMipmaps=!1),i.needsUpdate=!0,i}var Bf=.5,Vf=new Zs(new Uint8Array([255,255,255,255]),1,1);Vf.needsUpdate=!0;var Hf=class extends ei{maps=[];frameSources=[];frameMaps=new Map;frameLayer=null;noMips;frame=0;notes=[];screenCopy;constructor(e){e={...e,drawMode:cd(e.drawMode)};let t=!!e.decal&&J.decalNoMipmaps,n=(e,t=!1)=>e?Rf(e.layer,t):1,r=e.layer1?zf(e.layer1.texture,e.layer1.layer,t,n(e.layer1,!0)):null,i=e.layer2?zf(e.layer2.texture,e.layer2.layer,t,n(e.layer2,!0)):null,a=e.distortion?zf(e.distortion.texture,e.distortion.layer,t,n(e.distortion,!0)):null,o=e.layer3?zf(e.layer3.texture,e.layer3.layer,t,n(e.layer3)):null,s=e.layer4?zf(e.layer4.texture,e.layer4.layer,t,n(e.layer4)):null,c=e.palette?e.palette.texture.clone():null;c&&e.palette&&(c.wrapS=c.wrapT=Ff(e.palette.border),c.needsUpdate=!0);let l=t=>e.distortion&&t&&e.distortion.layer.targets[t.layer.uvSet]?1:0,u=e=>J.textureAddAlphaOnlyNoColor&&e.layer.calcColor===1&&e.texture.userData.alphaOnly||J.textureCalcColor5None&&e.layer.calcColor===5?9:e.layer.calcColor,d=e=>e?new B(1,u(e),e.layer.calcAlpha,+!!e.layer.colorToAlpha):new B(0,0,0,0);switch(super({vertexShader:Nf,fragmentShader:Pf,uniforms:{particleColor:{value:new B(1,1,1,1)},map1:{value:r??Vf},map2:{value:i??Vf},layer1:{value:d(e.layer1)},layer2:{value:d(e.layer2)},map4:{value:o??Vf},map5:{value:s??Vf},layer3:{value:d(e.layer3)},layer4:{value:d(e.layer4)},layerBias:{value:new B(Lf(n(e.layer1,!0)),Lf(n(e.layer2,!0)),Lf(n(e.layer3)),Lf(n(e.layer4)))},layerAniso:{value:new B(...[n(e.layer1,!0),n(e.layer2,!0),n(e.layer3),n(e.layer4)].map(e=>If[e]??1))},distortBias:{value:Lf(n(e.distortion,!0))},distortAniso:{value:If[n(e.distortion,!0)]??1},map6:{value:c??Vf},paletteOffset:{value:0},uvTransform1:{value:new z},uvTransform2:{value:new z},uvTransform3:{value:new z},uvTransform4:{value:new z},uvTransform5:{value:new z},sceneDepth:{value:null},sceneDepthSize:{value:new R(1,1)},decalViewToWorld:{value:new U},decalWorldToLocal:{value:new U},decalInverseProjection:{value:new U},decalGround:{value:0},decalRing:{value:new H(0,.5,Math.PI)},decalExtent:{value:1},cameraNearFar:{value:new R(.1,1e3)},softDepthOn:{value:0},sceneColor:{value:null},sceneColorSize:{value:new R(1,1)},screenCopyOn:{value:0},uvChannel:{value:new H(e.layer1?.layer.uvSet??0,e.layer2?.layer.uvSet??0,e.distortion?.layer.uvSet??0)},uvChannel34:{value:new R(e.layer3?.layer.uvSet??0,e.layer4?.layer.uvSet??0)},map3:{value:a??Vf},distortLayers:{value:new B(l(e.layer1),l(e.layer2),l(e.layer3),l(e.layer4))},distortPower:{value:0},depthOffset:{value:0},colorBegin:{value:new B(1,1,1,1)},colorEnd:{value:new B(1,1,1,1)},fresnelPower:{value:1},lightDir:{value:new H(0,1,0)},lightAmbient:{value:new H},lightColor:{value:new H}},defines:{...e.vertexColors?{USE_VERTEX_COLOR:``}:{},...e.fresnel?{FRESNEL:``}:{},...e.lit==null?{}:{LIT:String(e.lit===1||e.lit===2?e.lit:0)},...e.modelUvs?{MODEL_UVS:``}:{},...e.soft?{SOFT:``,SOFT_DISTANCE:Math.max(.001,e.softDistance??Bf).toFixed(4),...J.softUsesDepthOffset?{SOFT_OFFSET:``}:{},...J.softQuadratic?{SOFT_QUADRATIC:``}:{}}:{},...a?{DISTORTION:``,...J.distortionHalfRange?{DISTORT_HALF:``}:{},...J.distortionKeepsFootprint?{DISTORT_GRAD:``}:{}}:{},...c?{PALETTE:``,...J.paletteChannels&&e.layer1?{PALETTE_CHANNELS:``}:{}}:{},...e.lineGradient?{LINE_GRADIENT:``}:{},...J.colorToAlphaSharp?{C2A_SHARP:``}:{},...J.textureAddByAlpha?{ADD_BY_ALPHA:``}:{},...J.tc1MultiplyLuminance?{TC1_MULTIPLY_LUMA:``}:{},...J.tc1MultiplyLuminance&&J.tc1MultiplyIgnoresColor?{TC1_MULTIPLY_WHITE:``}:{},...e.screenCopy?{SCREEN_COPY:``}:{},...e.decalProject?{DECAL_PROJECT:``,...e.decalProject===`ring`?{DECAL_RING:``}:{}}:{},...e.tc1White&&!e.layer1&&!e.screenCopy?{TC1_WHITE:``}:{},...e.tc1White&&e.tc1Off&&!e.layer1&&!e.screenCopy&&J.tc1OffNoAlpha&&(e.layer2||e.layer3||e.layer4)?{TC1_OFF_NO_ALPHA:``}:{},...e.sprites?{SPRITES:``}:{},...e.drawMode===sd.Screen||e.drawMode===sd.Subtract||J.blendBeforeClamp&&(e.drawMode===sd.Blend||e.drawMode===sd.Opacity)||J.addBeforeClamp&&e.drawMode===sd.Add?{PREMULTIPLY:``}:{},...e.drawMode===sd.Multiply?{MULTIPLY:``}:{}},transparent:!0,toneMapped:!1,depthTest:!e.decalProject&&e.depthTest,depthWrite:e.depthWrite,side:e.decalProject?1:e.decal?2:e.culling===gd.Back?+!!J.cullingD3DWinding:e.culling===gd.Front?+!J.cullingD3DWinding:2}),r&&this.maps.push(r),i&&this.maps.push(i),a&&this.maps.push(a),o&&this.maps.push(o),s&&this.maps.push(s),c&&this.maps.push(c),this.screenCopy=!!e.screenCopy,this.noMips=t,e.layer1&&r&&(this.frameSources=e.layer1.frames??[e.layer1.texture],this.frameLayer=e.layer1.layer,this.frameMaps.set(0,r)),e.drawMode){case sd.Add:J.addBeforeClamp?(this.blending=5,this.blendSrc=201,this.blendDst=201,this.blendSrcAlpha=200,this.blendDstAlpha=201):this.blending=2;break;case sd.Subtract:this.blending=3;break;case sd.Multiply:this.blending=5,this.blendSrc=208,this.blendDst=200,this.blendSrcAlpha=200,this.blendDstAlpha=201;break;case sd.Screen:this.blending=5,this.blendSrc=209,this.blendDst=201;break;case sd.Blend:case sd.Opacity:J.blendBeforeClamp?(this.blending=5,this.blendSrc=201,this.blendDst=205,this.blendSrcAlpha=201,this.blendDstAlpha=205):this.blending=1;break;default:this.blending=1,this.notes.push(`draw mode ${e.drawMode} approximated as blend`)}}setColor(e,t,n,r){this.uniforms.particleColor.value.set(e,t,n,r)}setSceneColor(e,t,n){this.uniforms.sceneColor.value=e,this.uniforms.screenCopyOn.value=+!!e,this.uniforms.sceneColorSize.value.set(t,n)}setSceneDepth(e,t,n,r,i){this.uniforms.sceneDepth.value=e,this.uniforms.softDepthOn.value=+!!e,this.uniforms.sceneDepthSize.value.set(t,n),this.uniforms.cameraNearFar.value.set(r,i)}setDecalProjection(e,t,n,r,i){this.uniforms.decalViewToWorld.value.copy(e),this.uniforms.decalWorldToLocal.value.copy(n),this.uniforms.decalInverseProjection.value.copy(t),this.uniforms.decalGround.value=r,i&&this.uniforms.decalRing.value.set(i[0],i[1],i[2]),this.uniforms.decalExtent.value=i?Math.max(1,2*i[1]):1}setLight(e,t,n){this.uniforms.lightDir.value.copy(e),this.uniforms.lightAmbient.value.copy(t),this.uniforms.lightColor.value.copy(n)}setColorEnds(e,t,n=1){this.uniforms.colorBegin.value.copy(e),this.uniforms.colorEnd.value.copy(t),this.uniforms.fresnelPower.value=Math.max(n,.001)}setDepthOffset(e){this.uniforms.depthOffset.value=e}setDistortPower(e){this.uniforms.distortPower.value=e}setPaletteOffset(e){this.uniforms.paletteOffset.value=e}setUv(e,t,n,r,i,a){this.uniforms[`uvTransform${e}`].value.setUvTransform(r,i,t,n,a,0,0)}get frameCount(){return this.frameSources.length}setFrame(e){if(e===this.frame||!this.frameLayer)return;let t=this.frameSources[e];if(!t)return;let n=this.frameMaps.get(e);n||(n=zf(t,this.frameLayer,this.noMips,Rf(this.frameLayer,!0)),this.frameMaps.set(e,n),this.maps.push(n)),this.uniforms.map1.value=n,this.frame=e}dispose(){for(let e of this.maps)e.dispose();super.dispose()}},Uf=()=>({dissolveOn:{value:0},dissolveMap:{value:null},dissolveUv:{value:new z},dissolveAmount:{value:0},dissolveWidth:{value:.2},dissolveMid:{value:.5},dissolveReverse:{value:0},dissolveMode:{value:0},dissolveTexOn:{value:0},dissolveShape:{value:new U},dissolveSoft:{value:.1},dissolveDistOn:{value:0},dissolveDistMap:{value:null},dissolveDistUv:{value:new z},dissolveDistPow:{value:0},dissolveColors:{value:[new B,new B,new B]},dissolveGlow:{value:1}}),Wf=!1;function Gf(){if(Wf)return!0;let e=G.lights_pars_begin,t=`float getDistanceAttenuation( const in float lightDistance, const in float cutoffDistance, const in float decayExponent ) {`;return e.includes(t)?(G.lights_pars_begin=e.replace(t,`${t}
	/* game point light */
	if ( decayExponent < 0.0 ) return min( 1.0, cutoffDistance / max( pow( lightDistance, - decayExponent ), 1e-4 ) );`),Wf=!0,!0):(console.warn(`avfx: three.js lights_pars_begin has no getDistanceAttenuation to extend; effect lights keep three.js falloff`),!1)}var Kf=new WeakMap,qf=new WeakMap,Jf=class e{mesh;material;backend;cloud;constructor(e,t,n,r){this.mesh=e,this.material=t,this.backend=n,this.cloud=r}get visible(){return this.mesh.visible}set visible(e){this.mesh.visible=e}get order(){return this.mesh.renderOrder}set order(e){this.mesh.renderOrder=e}get notes(){return this.material.notes}get frameCount(){return this.material.frameCount}setMatrix(e){this.mesh.matrix.copy(e),this.mesh.matrixWorld.copy(e),this.cloud&&(this.mesh.count=this.cloud.count)}setColor(e,t,n,r){this.material.setColor(e,t,n,r)}setDepthOffset(e){this.material.setDepthOffset(e)}useScene(e,t){let n=this.material;if(n.screenCopy){let e=this.backend.sceneColor;n.setSceneColor(e?.texture??null,e?.width??1,e?.height??1)}if(t&&e instanceof ai){let t=this.backend.sceneDepth;n.setSceneDepth(t?.texture??null,t?.width??1,t?.height??1,e.near,e.far)}}setColorEnds(e,t,n){this.material.setColorEnds(e,t,n)}setFrame(e){this.material.setFrame(e)}setUv(e,t,n,r,i,a){this.material.setUv(e,t,n,r,i,a)}setDistortPower(e){this.material.setDistortPower(e)}setPaletteOffset(e){this.material.setPaletteOffset(e)}setLight(e,t,n){this.material.setLight(e,t,n)}static worldToLocal=new U;setDecalProjection(t,n,r,i){let a=e.worldToLocal.copy(t).invert();this.material.setDecalProjection(n.matrixWorld,n.projectionMatrixInverse,a,r,i);let o=this.backend.sceneDepth,s=n instanceof ai?n.near:.1,c=n instanceof ai?n.far:1e3;this.material.setSceneDepth(o?.texture??null,o?.width??1,o?.height??1,s,c)}dispose(){this.mesh.removeFromParent(),this.material.dispose()}},Yf=class{light;constructor(e){this.light=e}set(e,t,n,r,i,a,o,s){let c=this.light;c.visible=e,c.position.copy(t),c.color.setRGB(n,r,i),c.intensity=a,Wf?(c.distance=o,c.decay=-s):(c.distance=0,c.decay=s,c.intensity*=o)}dispose(){this.light.removeFromParent(),this.light.dispose()}},Xf=class{particleLayer=new ys;debugLayer=new ys;debugWires=new Map;debugEmitters=new Map;sceneDepth=null;sceneColor=null;constructor(e){this.particleLayer.name=`${e} particles`}attach(e){let t=e;for(;t.parent;)t=t.parent;this.particleLayer.parent!==t&&t!==e&&t.add(this.particleLayer),this.debugLayer.parent!==t&&t!==e&&t.add(this.debugLayer)}createVisual(e,t,n,r){let i=new Hf(n);e.type===Y.ModelSkin&&(i.polygonOffset=!0,i.polygonOffsetFactor=-2,i.polygonOffsetUnits=-2);let a;if(r){let e=new oc(r.geometry,i,r.capacity);e.instanceMatrix=r.instanceMatrix,e.count=r.count,a=e}else a=new Ur(t,i);return a.matrixAutoUpdate=!1,a.frustumCulled=!1,this.particleLayer.add(a),new Jf(a,i,this,r)}createLight(e){let t=new Fl;return t.name=e,this.particleLayer.add(t),new Yf(t)}setSceneDepth(e,t,n){this.sceneDepth=e?{texture:e,width:t,height:n}:null}setSceneColor(e,t,n){this.sceneColor=e?{texture:e,width:t,height:n}:null}dissolveUniforms(e){let t=Kf.get(e.object);return t||Kf.set(e.object,t=Uf()),t}dissolveUsed=null;dissolveTextures=new Map;patchDissolve(e,t){for(let n of e)for(let e of Array.isArray(n.material)?n.material:[n.material])this.patchMaterial(e,t)}dissolveTexture(e){let t=this.dissolveTextures.get(e);return t||(t=e.clone(),t.wrapS=t.wrapT=r,t.needsUpdate=!0,this.dissolveTextures.set(e,t)),t}patchMaterial(e,t){if(this.dissolveUsed=t,qf.has(e))return;qf.set(e,t);let n=e.onBeforeCompile,r=Object.prototype.hasOwnProperty.call(e,`customProgramCacheKey`)?e.customProgramCacheKey.bind(e):()=>n.toString();e.customProgramCacheKey=()=>`${r()}|avfx-dissolve`,e.onBeforeCompile=(r,i)=>{n.call(e,r,i);let a=[r.vertexShader,r.vertexShader,r.vertexShader,r.fragmentShader,r.fragmentShader];if([`void main() {`,`#include <defaultnormal_vertex>`,`#include <skinning_vertex>`,`void main() {`,`#include <dithering_fragment>`].some((e,t)=>!a[t].includes(e))){console.warn(`avfx: Dissolve — material ${e.name||e.type} has no place for the patch; left as it is`);return}Object.assign(r.uniforms,t),r.vertexShader=r.vertexShader.replace(`void main() {`,`varying vec3 vDissolvePos;
varying vec3 vDissolveNormal;
varying vec3 vDissolveWorld;
void main() {`).replace(`#include <defaultnormal_vertex>`,`#include <defaultnormal_vertex>
  vDissolveNormal = objectNormal;`).replace(`#include <skinning_vertex>`,`#include <skinning_vertex>
  vDissolvePos = transformed;
  vDissolveWorld = (modelMatrix * vec4(transformed, 1.0)).xyz;`),r.fragmentShader=r.fragmentShader.replace(`void main() {`,`uniform int dissolveOn; uniform sampler2D dissolveMap; uniform mat3 dissolveUv; uniform float dissolveAmount;
uniform float dissolveWidth; uniform float dissolveMid; uniform int dissolveReverse; uniform vec4 dissolveColors[3];
uniform float dissolveGlow; uniform int dissolveMode; uniform int dissolveTexOn; uniform mat4 dissolveShape; uniform float dissolveSoft;
uniform int dissolveDistOn; uniform sampler2D dissolveDistMap; uniform mat3 dissolveDistUv; uniform float dissolveDistPow;
varying vec3 vDissolvePos; varying vec3 vDissolveNormal; varying vec3 vDissolveWorld;
void main() {`).replace(`#include <dithering_fragment>`,`#include <dithering_fragment>
  if (dissolveOn == 1) {
    // character.shpk: three planar lookups (zy, xz, xy) weighted by the normalised |normal|, red, saturated.
    vec3 w = normalize(abs(vDissolveNormal) + 1e-5);
    vec2 dshift = vec2(0.0);
    if (dissolveDistOn == 1) dshift = (
      texture2D(dissolveDistMap, (dissolveDistUv * vec3(vDissolvePos.zy, 1.0)).xy).rg * w.x +
      texture2D(dissolveDistMap, (dissolveDistUv * vec3(vDissolvePos.xz, 1.0)).xy).rg * w.y +
      texture2D(dissolveDistMap, (dissolveDistUv * vec3(vDissolvePos.xy, 1.0)).xy).rg * w.z) * dissolveDistPow;
    float n = dissolveTexOn == 1 ? clamp(
      texture2D(dissolveMap, (dissolveUv * vec3(vDissolvePos.zy, 1.0)).xy + dshift).r * w.x +
      texture2D(dissolveMap, (dissolveUv * vec3(vDissolvePos.xz, 1.0)).xy + dshift).r * w.y +
      texture2D(dissolveMap, (dissolveUv * vec3(vDissolvePos.xy, 1.0)).xy + dshift).r * w.z, 0.0, 1.0) : 1.0;
    float amount = dissolveAmount;
    if (dissolveMode == 0) {
      if (dissolveReverse == 1) n = 1.0 - n;
    } else {
      // character.shpk shape branch: p in the shape's space; the distance outside the unit shape over the soft zone
      // gives q; inside (q < 0, Reverse flips the side) is cut away; past the zone (q ≥ 1) untouched; within it the
      // shape acts as an Erosion of 1 − q.
      vec3 sp = (dissolveShape * vec4(vDissolveWorld, 1.0)).xyz;
      float sgn = dissolveReverse == 1 ? -1.0 : 1.0;
      float q;
      if (dissolveMode == 2) q = sgn * (length(sp) - 1.0) / dissolveSoft;
      else if (dissolveMode == 1) q = sgn * (max(max(abs(sp.x), abs(sp.y)), abs(sp.z)) - 1.0) / dissolveSoft;
      else q = sgn * max(length(sp.xz) - 1.0, abs(sp.y) - 1.0) / dissolveSoft;
      if (q < 0.0) discard;
      if (q >= 1.0) amount = -1.0;
      else amount = 1.0 - q;
    }
    float y = (n - amount) * 1.001 - 0.001;
    if (y < 0.0) discard;
    if (amount < 0.0) { /* outside the shape's zone: the surface as is */ }
    else {
    float t1 = clamp(y / dissolveWidth, 0.0, 1.0);
    float t = clamp(t1 / dissolveWidth, 0.0, 1.0);
    vec3 surf = gl_FragColor.rgb;
    vec3 c0 = mix(surf, dissolveColors[0].rgb, dissolveColors[0].w);
    vec3 c1 = mix(surf, dissolveColors[1].rgb, dissolveColors[1].w);
    vec3 c2 = mix(surf, dissolveColors[2].rgb, dissolveColors[2].w);
    vec3 band = t < dissolveMid ? mix(c0, c1, t / dissolveMid) : mix(c1, c2, (t - dissolveMid) / (1.0 - dissolveMid));
    float s = clamp(amount * 5.0, 0.0, 1.0);
    float k = min(1.0, s * s * (3.0 - 2.0 * s) * (1.0 - t1));
    gl_FragColor.rgb = mix(surf, band, k);
    // The shader also writes the band into the glow output, × a parameter (assumptions.dissolveOnCharacter: Int, × 1).
    vec3 g0 = dissolveColors[0].rgb * dissolveColors[0].w;
    vec3 g1 = dissolveColors[1].rgb * dissolveColors[1].w;
    vec3 g2 = dissolveColors[2].rgb * dissolveColors[2].w;
    vec3 glow = t < dissolveMid ? mix(g0, g1, t / dissolveMid) : mix(g1, g2, (t - dissolveMid) / (1.0 - dissolveMid));
    gl_FragColor.rgb += glow * dissolveGlow * k;
    }
  }`)},e.needsUpdate=!0}restoreDissolve(){this.dissolveUsed&&=(this.dissolveUsed.dissolveOn.value=0,this.dissolveUsed.dissolveMap.value=null,this.dissolveUsed.dissolveDistMap.value=null,null);for(let e of this.dissolveTextures.values())e.dispose();this.dissolveTextures.clear()}clearDebug(){for(let e of this.debugWires.values())e.removeFromParent(),e.material.dispose();this.debugWires.clear();for(let e of this.debugEmitters.values())e.removeFromParent(),e.traverse(e=>{(e instanceof Tc||e instanceof yc)&&(e.geometry.dispose(),e.material.dispose())});this.debugEmitters.clear()}renderDebug(e,t,n){let r=e=>new W().setHSL(e*.618034%1,.85,.6),i=new Set;if(e.wireframe)for(let e of t){let t=e.visual?.mesh;if(!t)continue;i.add(e);let n=this.debugWires.get(e);if(!n){let i=new _r({color:r(e.schema.index),wireframe:!0,transparent:!0,opacity:.7,depthTest:!1,depthWrite:!1});if(t instanceof oc){let e=new oc(t.geometry,i,t.instanceMatrix.count);e.instanceMatrix=t.instanceMatrix,n=e}else n=new Ur(t.geometry,i);n.matrixAutoUpdate=!1,n.frustumCulled=!1,n.renderOrder=0x2386f26fc10000,this.debugLayer.add(n),this.debugWires.set(e,n)}n.geometry=t.geometry,n instanceof oc&&t instanceof oc&&(n.instanceMatrix=t.instanceMatrix,n.count=t.count),n.visible=t.visible,n.matrix.copy(t.matrix),n.matrixWorld.copy(t.matrixWorld)}for(let[e,t]of this.debugWires)i.has(e)||(t.removeFromParent(),t.material.dispose(),this.debugWires.delete(e));let a=new Set;if(e.emitters)for(let e of n){a.add(e);let t=this.debugEmitters.get(e);if(!t){t=new ys,t.matrixAutoUpdate=!1;let n=r(e.schema.index+7),i=new eu(.4);if(i.material.depthTest=!1,i.renderOrder=0x2386f26fc10000,t.add(i),e.points.length){let r=new Tc(new jr().setFromPoints(e.points.map(e=>e.position)),new bc({color:n,size:6,sizeAttenuation:!1,depthTest:!1}));r.renderOrder=0x2386f26fc10000,r.name=`shape`,t.add(r)}this.debugLayer.add(t),this.debugEmitters.set(e,t)}t.matrix.copy(e.world);let n=t.getObjectByName(`shape`);if(n){let t=e.schema.type===od.SphereModel?$(e.schema.radius,e.age,1):1;n.matrix.makeScale(t,t,t),n.matrixAutoUpdate=!1}t.updateMatrixWorld(!0)}for(let[e,t]of this.debugEmitters)a.has(e)||(t.removeFromParent(),t.traverse(e=>{(e instanceof Tc||e instanceof yc)&&(e.geometry.dispose(),e.material.dispose())}),this.debugEmitters.delete(e))}dispose(){this.clearDebug(),this.particleLayer.removeFromParent(),this.debugLayer.removeFromParent()}},Zf=J.rotationOrderIsApplyOrder?[`ZYX`,`XZY`,`YXZ`,`YZX`,`ZXY`,`XYZ`]:[`XYZ`,`YZX`,`ZXY`,`XZY`,`YXZ`,`ZYX`],Qf=()=>[0,0,0];function $f(e,t,n,r=0){if(e<0)return 1/0;let i=J.lifeRandomType?r===pd.FirstPlus||r===pd.AlwaysPlus?t*n:r===pd.FirstMinus||r===pd.AlwaysMinus?-t*n:t*(n*2-1):t*(n*2-1);return Math.max(1,e+i)}function ep(e){let t=e.clone().normalize(),n=new H(0,1,0).addScaledVector(t,-t.y);return n.lengthSq()<1e-8&&n.set(1,0,0).addScaledVector(t,-t.x),n.normalize(),new U().makeBasis(new H().crossVectors(n,t),n,t)}function tp(e,t,n,r,i,a=0){let o=new V().setFromEuler(new Mn(t[0],t[1],t[2],Zf[r]??`XYZ`));if(!a||!J.coordComputeOrder)return i.compose(new H(...e),o,new H(...n));let s={S:new U().makeScale(...n),R:new U().makeRotationFromQuaternion(o),T:new U().makeTranslation(...e)},c=[`SRT`,`TSR`,`RTS`,`TRS`,`STR`,`RST`][a]??`SRT`;i.identity();for(let e of c)i.premultiply(s[e]);return i}function np(e,t,n){let r=Math.max(1,e.divideX),i=Math.max(1,e.divideY),a=$(e.radius,t,1),o=$(e.injectionAngle,t,0)+n,s=[];e.generateMethod<ud.RandomToVertexWithoutSingularPoint&&s.push({position:new H(0,0,a),normal:new H(0,0,1)});for(let e=1;e<=i;e++){let t=o*e/i;for(let e=0;e<r;e++){let n=-Math.PI/2+e/r*Math.PI*2,i=new H(Math.sin(t)*Math.cos(n),Math.sin(t)*Math.sin(n),Math.cos(t));s.push({position:i.clone().multiplyScalar(a),normal:i})}}return s}function rp(e,t){let n=Math.max(1,e.divideX),r=Math.max(0,e.divideY),i=$(e.radius,t,1),a=$(e.length,t,0),o=[];for(let e=0;e<=r;e++){let t=r>0?(e/r-.5)*a:0;for(let e=0;e<n;e++){let r=e/n*Math.PI*2,a=J.ringStartZ?new H(Math.sin(r),0,Math.cos(r)):new H(Math.cos(r),0,Math.sin(r));o.push({position:a.clone().multiplyScalar(i).setY(t),normal:a})}}return o}function ip(e){let t=Math.max(1,e.divideX),n=Math.max(1,e.divideY),r=e.generateMethod<ud.RandomToVertexWithoutSingularPoint,i=[];r&&i.push(new H(0,1,0));for(let e=1;e<n;e++){let r=Math.PI*e/n;for(let e=0;e<t;e++){let n=e/t*Math.PI*2;i.push(J.ringStartZ?new H(Math.sin(r)*Math.sin(n),Math.cos(r),Math.sin(r)*Math.cos(n)):new H(Math.sin(r)*Math.cos(n),Math.cos(r),Math.sin(r)*Math.sin(n)))}}return r&&i.push(new H(0,-1,0)),i}function ap(e,t,n,r,i=!1){let a=e.rgb?Yd(e.rgb,t,Qf()):[1,1,1],o=$(e.bri,t,1)+Zd(e.ranBri,t,n.get(7));return r.set((a[0]+Zd(e.ranR,t,n.get(20)))*$(e.sclR,t,1)*o,(a[1]+Zd(e.ranG,t,n.get(21)))*$(e.sclG,t,1)*o,(a[2]+Zd(e.ranB,t,n.get(22)))*$(e.sclB,t,1)*o,($(e.a,t,1)+Zd(e.ranA,t,n.get(23)))*$(e.sclA,t,1)*(i?Math.max(0,o):1)),r}function op(e){return e.createTime===1||J.createTimeLast&&e.createTime===2||!J.createTimeZeroMakesOne?Math.max(0,e.createCount):1}function sp(e,t,n,r){let i=new H,a=new V,o=new H,s=new H,c=new V,l=new H;return e.decompose(i,a,o),t.decompose(s,c,l),r.compose(i.lerp(s,n),a.slerp(c,n),o.lerp(l,n))}var cp=class e{schema;anchor;age=0;totalAge=0;world=new U;stepWorld=new U;stepStart=null;color=new B(1,1,1,1);seed=new Wd;nextSpawn;nextChild;order=0;lifetime;points=[];stopped=!1;timeline=-1;spawnOrder=0;binder=-1;ancestors=[];parent=null;posInWorld=!1;timeScale=1;colorFrom=null;startQuat=null;injected=new Map;velocity=new H;motion=new H;travel=new H;rotZ=0;injectZ=0;launch=null;fall=0;moving=!1;moveDir=new H;lastPos=null;get stillMoveDirection(){return J.emitterMoveDirection&&this.schema.rotationBase===ld.MoveDirection&&this.moveDir.lengthSq()===0}constructor(e,t,n){this.schema=e,this.anchor=t;let r=$f(e.life.value,e.life.random,this.seed.get(0),e.life.randomType);this.lifetime=Math.min(r,n>0?n:1/0);let i=t=>{let n=Math.max(0,t.generateDelay);if(!J.createTimeLast||t.createTime!==2||!Number.isFinite(this.lifetime)||this.loops)return n;let r=$(e.createInterval,0,0);return r>0?Math.max(n,Math.floor((this.lifetime-1)/r)*r):n};this.nextSpawn=e.particleItems.map(i),this.nextChild=e.emitterItems.map(i)}holdWhile=null;get alive(){return this.age<this.lifetime||(this.holdWhile?.()??!1)}matrixFor(e,t){let n=this.schema,r=this.curveTime,i=Qd(n.position,r,0,e,1,Qf()),a=Qd(n.rotation,r,0,e,4,Qf()),o=Qd(n.scale,r,1,e,8,Qf());return this.place(i,a,o,t)}get curveTime(){return J.emitterPeriodicCurvesIgnoreLoop?{t:this.age,total:this.totalAge}:this.age}updateTransform(){let e=this.schema,t=this.curveTime,n=Qd(e.position,t,0,this.seed,1,Qf()),r=Qd(e.rotation,t,0,this.seed,4,Qf()),i=Qd(e.scale,t,1,this.seed,8,Qf());if(this.rotZ=r[2],this.place(n,r,i,this.world),J.emitterMoveDirection&&e.rotationBase===ld.MoveDirection){let a=new H().setFromMatrixPosition(this.world),o=this.lastPos;if(!o){let n=typeof t==`number`?t+.5:{t:t.t+.5,total:t.total+.5},s=new H().setFromMatrixPosition(this.place(Qd(e.position,n,0,this.seed,1,Qf()),r,i,new U));o=a.clone().sub(s.sub(a))}a.distanceToSquared(o)>1e-10&&(this.moveDir.subVectors(a,o),this.place(n,r,i,this.world)),this.lastPos=a}if(ap(e.color,t,this.seed,this.color),this.colorFrom){let e=this.colorFrom.mode===2&&this.parent?this.parent.color:this.colorFrom.initial;this.color.set(this.color.x*e.x,this.color.y*e.y,this.color.z*e.z,this.color.w*e.w)}}curveMotion(e){let t=this.schema,n=this.curveTime,r=typeof n==`number`?n+.5:{t:n.t+.5,total:n.total+.5},i=new H().setFromMatrixPosition(this.place(Qd(t.position,r,0,this.seed,1,Qf()),Qd(t.rotation,r,0,this.seed,4,Qf()),Qd(t.scale,r,1,this.seed,8,Qf()),new U));return e.copy(i.sub(new H().setFromMatrixPosition(this.world)).multiplyScalar(2))}static cameraQuat=null;place(t,n,r,i){let a=this.schema;this.posInWorld?(i.multiplyMatrices(this.anchor(),tp([0,0,0],n,r,a.rotationOrder,new U)),i.elements[12]+=t[0],i.elements[13]+=t[1],i.elements[14]+=t[2]):i.multiplyMatrices(this.anchor(),tp(t,n,r,a.rotationOrder,new U,a.coordOrder));let o=e.cameraQuat;if(J.emitterCameraBillboardAxisY&&o&&a.rotationBase===ld.CameraBillboardAxisY){let e=new H,t=new V,r=new H;i.decompose(e,t,r),t.copy(o).multiply(new V().setFromEuler(new Mn(n[0],n[1],n[2],Zf[a.rotationOrder]??`XYZ`))),i.compose(e,t,r)}if(this.moving&&i.premultiply(new U().makeTranslation(this.travel)),J.emitterMoveDirection&&a.rotationBase===ld.MoveDirection&&this.moveDir.lengthSq()>0){let e=new H,t=new V,r=new H;i.decompose(e,t,r);let o=this.moveDir.clone().normalize(),s=Math.abs(o.y)>.999?new H(0,0,-1):new H(0,1,0),c=new H().crossVectors(s,o).normalize(),l=new H().crossVectors(o,c);t.setFromRotationMatrix(new U().makeBasis(c,l,o)).multiply(new V().setFromEuler(new Mn(n[0],n[1],n[2],Zf[a.rotationOrder]??`XYZ`))),i.compose(e,t,r)}return i}speedDraw;speedRandom(){let e=this.schema.injectionSpeedRandom;return e?J.injectionSpeedRandomPerEmitter?e.random>=pd.AlwaysPlusMinus?Zd(e,this.age,Vd()):this.speedDraw??=Zd(e,0,Vd()):$(e,this.age,0)*(Vd()*2-1):0}coneDelta=0;shapeDraws=[];shapeRandom(e,t){return e?e.random>=pd.AlwaysPlusMinus?Zd(e,this.age,Vd()):this.shapeDraws[t]??=Zd(e,0,Vd()):0}shapeAngles(){let e=this.schema;return e.coneAngles.map((t,n)=>$(t,this.age,0)+this.shapeRandom(e.coneAnglesRandom[n],n))}injectionTurn(e,t){let n=this.schema,r=n.anyDirection?J.emitterInjectionAngle:J.emitterVelocityAngle;if(r===`off`||r===`flight`)return null;let i=(n.anyDirection?n.injectAngles:n.velocityRandom).map((e,r)=>$(e,this.age,0)+(n.anyDirection?n.injectAnglesRandom[r]&&n.injectAnglesRandom[r].random>=pd.AlwaysPlusMinus?Zd(n.injectAnglesRandom[r],this.age,t(r)):this.shapeRandom(n.injectAnglesRandom[r],6+r):0));if(!i[0]&&!i[1]&&!i[2])return null;let a=new V().setFromEuler(new Mn(i[0],i[1],i[2],Zf[n.rotationOrder]??`XYZ`));if(r!==`point`||!e||e.normal.lengthSq()<1e-8)return a;let o=new V().setFromRotationMatrix(ep(e.normal));return o.clone().multiply(a).multiply(o.invert())}nextPoint(){let e=this.shapePoint(),t=this.schema.type;if(e&&J.shapeAngles&&(t===od.CylinderModel||t===od.SphereModel||t===od.ConeModel||t===od.Model)){let[t,n,r]=this.shapeAngles();if(t||n||r){let i=new Mn(t,n,r,Zf[this.schema.coneRotationOrder]??`XYZ`);return{position:e.position.clone().applyEuler(i),normal:e.normal.clone().applyEuler(i)}}}return e}shapePoint(){if(J.coneModelRings&&this.schema.type===od.ConeModel&&this.points.length){let e=this.schema.generateMethod,t=e===ud.OrderOnVertex||e===ud.OrderToVertex||e===ud.OrderOnVertexWithoutSingularPoint||e===ud.OrderToVertexWithoutSingularPoint,n=this.schema;((n.radius?.keys.length??0)>1||(n.injectionAngle?.keys.length??0)>1)&&(this.points=np(n,this.age,this.coneDelta));let r=this.points[t?this.order++%this.points.length:Math.floor(Vd()*this.points.length)],i=e===ud.RandomOnVertex||e===ud.OrderOnVertex||e===ud.RandomOnVertexWithoutSingularPoint||e===ud.OrderOnVertexWithoutSingularPoint,a=$(n.radius,this.age,1),o=n.radiusRandom&&a?1+this.shapeRandom(n.radiusRandom,3)/a:1,s=r.normal.clone();return{position:i?s.clone().multiplyScalar(r.position.length()*o):new H,normal:s}}if(J.coneEmitter&&(this.schema.type===od.Cone||this.schema.type===od.ConeModel))return this.conePoint();if(!this.points.length)return null;if(this.schema.type===od.SphereModel)return this.spherePoint();let e=this.schema;e.type===od.CylinderModel&&((e.radius?.keys.length??0)>1||(e.length?.keys.length??0)>1)&&(this.points=rp(e,this.age));let t=this.schema.generateMethod,n=t===ud.OrderOnVertex||t===ud.OrderToVertex||t===ud.OrderOnVertexWithoutSingularPoint||t===ud.OrderToVertexWithoutSingularPoint?this.order++%this.points.length:Math.floor(Vd()*this.points.length),r=this.points[n];if(J.modelToVertexFromCentre&&this.schema.type===od.Model&&(t===ud.RandomToVertex||t===ud.OrderToVertex||t===ud.RandomToVertexWithoutSingularPoint||t===ud.OrderToVertexWithoutSingularPoint))return{position:new H,normal:r.position.lengthSq()>1e-12?r.position.clone().normalize():r.normal.clone()};if(this.schema.type===od.CylinderModel){if(t!==ud.RandomOnVertex&&t!==ud.OrderOnVertex&&t!==ud.RandomOnVertexWithoutSingularPoint&&t!==ud.OrderOnVertexWithoutSingularPoint)return{position:new H,normal:r.position.clone().normalize()};if(J.cylinderTangentFlight){let e=J.ringStartZ?new H(r.normal.z,0,-r.normal.x):new H(-r.normal.z,0,r.normal.x);return{position:r.position,normal:e}}}return r}conePoint(){let e=this.schema,t=Math.max(0,$(e.injectionAngle,this.age,0)+$(e.injectionAngleRandom,this.age,0)*(Vd()*2-1)),n=1-Vd()*(1-Math.cos(Math.min(Math.PI,t))),r=Math.sqrt(Math.max(0,1-n*n)),i=Vd()*Math.PI*2,a=new H(r*Math.cos(i),r*Math.sin(i),n),[o,s,c]=this.shapeAngles();if(a.applyEuler(new Mn(o,s,c,Zf[e.coneRotationOrder]??`XYZ`)),J.coneSizes&&e.type===od.Cone){let t=(e,t,n)=>$(e,this.age,0)+this.shapeRandom(t,n),n=t(e.innerSize,e.innerSizeRandom,4),r=t(e.outerSize,e.outerSizeRandom,5);return{position:a.clone().multiplyScalar(n+Vd()*(r-n)),normal:a}}return{position:new H,normal:a}}spherePoint(){let e=this.schema.generateMethod,t=e===ud.OrderOnVertex||e===ud.OrderToVertex||e===ud.OrderOnVertexWithoutSingularPoint||e===ud.OrderToVertexWithoutSingularPoint,n=this.points[t?this.order++%this.points.length:Math.floor(Vd()*this.points.length)].normal;if(e!==ud.RandomOnVertex&&e!==ud.OrderOnVertex&&e!==ud.RandomOnVertexWithoutSingularPoint&&e!==ud.OrderOnVertexWithoutSingularPoint)return{position:new H,normal:n.clone()};let r=$(this.schema.radius,this.age,1);return{position:n.clone().multiplyScalar(r),normal:J.sphereOnVertexInward?n.clone().negate():n.clone()}}liveChildren=0;wrap(e){this.age-=e,this.stepStart!==null&&(this.stepStart-=e);for(let t=0;t<this.nextSpawn.length;t++)this.nextSpawn[t]-=e;for(let t=0;t<this.nextChild.length;t++)this.nextChild[t]-=e}get loops(){return this.schema.loopEnd>this.schema.loopStart&&this.schema.loopStart>=0}stopItem(e){let t=this.schema.particleItems.indexOf(e);t>=0&&(this.nextSpawn[t]=1/0)}enterAge(e){if(!J.birthAtCreationTime||this.stepStart===null)return()=>{};let t=this.age-this.stepStart,n=t>0?(e-this.stepStart)/t:1;if(!(n>=0&&n<1))return()=>{};let r=this.world.clone();return sp(this.stepWorld,r,n,this.world),()=>this.world.copy(r)}sinceAge(e){return!J.birthAtCreationTime||this.stepStart===null||e<this.stepStart||e>this.age?0:(this.age-e)/(this.timeScale||1)}due(e,t){let n=e===`particle`?this.schema.particleItems:this.schema.emitterItems,r=e===`particle`?this.nextSpawn:this.nextChild,i=[];if(!this.alive||this.stopped)return i;for(let e=0;e<n.length;e++){let a=n[e];if(!a.enabled){r[e]=1/0;continue}let o=0;for(;this.age>=r[e]&&o++<t;){let t=r[e],n=this.schema.createCountRandom,o=J.createOnceIgnoresEmitterCount&&(a.createTime===1||J.createTimeLast&&a.createTime===2)?op(a):Math.round($(this.schema.createCount,t,1)+Zd(n,t,Vd()))*op(a);o>0&&i.push({item:a,count:o,at:t});let s=this.schema.createIntervalRandom,c=$(this.schema.createInterval,t,0)+Zd(s,t,Vd());J.createIntervalWholeFrame&&c>0&&(c=Math.max(1,c));let l=J.zeroCountItemOnce&&a.createTime===0&&a.createCount<=0?!1:J.createTimeRepeats?a.createTime===0:!J.emitterCreatesOnce||J.loopingEmittersRepeat&&this.loops;r[e]=c>0&&l?t+c:1/0}}return i}},lp=class{schema;item;emitter;visual;cloud;age=0;seed=new Wd(Vd,29);emitterSeed;spawnMatrix=new U;offset=new H;localFlight=!1;localTravel=new H;localVelocity=new H;velocity=new H;spin=null;travel=new H;lifetime;fresh=!0;copyIndex=0;stuck=null;normalFrame=null;link=null;linkSeed=new Wd(Vd,16);trail=null;geometry=null;timeScale;follow;withOptions;constructor(e,t,n,r,i=null,a=new Wd){this.schema=e,this.item=t,this.emitter=n,this.visual=r,this.cloud=i,this.emitterSeed=a;let o=t.overrideLife?$f(t.overrideLifeValue,t.overrideLifeRandom,this.seed.get(0)):$f(e.life.value,e.life.random,this.seed.get(0),e.life.randomType);this.lifetime=o;let s=e.life.value;this.timeScale=J.overrideLifeScalesCurves&&t.overrideLife&&s>0&&Number.isFinite(o)?s/o:1,this.follow=t.influenceCoord===hd.AllAlways||t.influenceCoord===hd.AllAlways_NoPosition||J.influenceUnknownFollows&&(t.influenceCoord===hd.Unknown||t.influenceCoord===hd.Unknown_NoPosition),this.withOptions=J.withOptionsFollow&&(t.influenceCoord===hd.InitialPosition_WithOptions||t.influenceCoord===hd.WithOptions_NoPosition),J.emitterRandomScope===`emitter`?this.spawnMatrix.copy(n.world):n.matrixFor(this.emitterSeed,this.spawnMatrix)}get alive(){return this.age<this.lifetime||this.cloud!==null&&!this.cloud.finished}totalAge=0;lastWorld=new H;hasLastWorld=!1;moveDir=new H;lastFlight=new H;get curveTime(){return{t:this.age*this.timeScale,total:this.totalAge*this.timeScale}}};function up(e,t,n,r,i){let a=t===vd.Target,o=(a?e.target??e.caster:e.caster)??e,s=n===bd.ByName?e.bindPoints.get(r):void 0;if(n===bd.ByName&&!s&&e.warnings.add(`binder #${i}: bind point ${r} (${Sd(r)}) not set; using ${a?`target`:`caster`} origin`),!a)return()=>(s??o).matrixWorld;let c=e.caster??e,l=new U,u=new U;return()=>s?l.multiplyMatrices(o.matrixWorld,u.copy(c.matrixWorld).invert().multiply(s.matrixWorld)):o.matrixWorld}function dp(e,t,n=e.time){let r=gp(e,t),i=e.schema.binders[t],a=i?.type===0?[i.updateFrames,i.life].filter(e=>e>0):[],o=a.length?Math.min(...a):-1;if(o<=0)return r;let s=n+o,c=null,l=null,u=n;return()=>{if(c)return c;let t=r();if(e.time>=s){let n=l&&e.time>u?(s-u)/(e.time-u):1;return c=n>=1||!l?t.clone():mp(l,t,n),c}return l=(l??new U).copy(t),u=e.time,t}}var fp={p:new H,q:new V,s:new H},pp={p:new H,q:new V,s:new H};function mp(e,t,n){return e.decompose(fp.p,fp.q,fp.s),t.decompose(pp.p,pp.q,pp.s),new U().compose(fp.p.lerp(pp.p,n),fp.q.slerp(pp.q,n),fp.s.lerp(pp.s,n))}function hp(e,t){let n=e.schema.revised,r=e.schema.binders[t]?.type;return tp(r===0||r===3?[0,0,0]:n.position,n.rotation,n.scale,0,new U)}function gp(e,t){let n=e.schema.binders[t];if(n?.type===3){let r=hp(e,t),i=new U().makeTranslation(0,0,$(n.distance,0,0)),a=new U;return()=>{let t=e.camera;return t?(t.updateMatrixWorld(),a.copy(t.matrixWorld).multiply(i).multiply(r)):a.copy(e.matrixWorld).multiply(r)}}if(J.binderLinearPath&&n?.goal&&n.carryOver&&(n.type===1||n.type===2||n.type===4)){let t=e.schema.revised,r=tp(t.position,t.rotation,t.scale,0,new U),i=up(e,n.bindPoint,n.bindTargetPoint,n.bindPointId,n.index),a=up(e,n.goal.bindPoint,n.goal.bindTargetPoint,n.goal.bindPointId,n.index),o=e.time,s=new U,c=new H,l=new V,u=new H,d=new H,f=n.type===2?n.rings??[]:[],p=n.carryOver.keys,m=Math.max(1,p[p.length-1].time),h=Math.abs(p[p.length-1].z)>1e-6?p[p.length-1].z:1,g=[0,...f.map(e=>Math.min(.999,Math.max(.001,e.time/m))),1],_=f.map(()=>Vd()*Math.PI*2),v=[c,...f.map(()=>new H),d],y=new H,b=new H,x=new H,S=new H,C=(e,t)=>{let n=Math.max(0,e-1),r=Math.min(v.length-1,e+1);return t.subVectors(v[r],v[n]).divideScalar(Math.max(1e-6,g[r]-g[n]))};return()=>{i().decompose(c,l,u),d.setFromMatrixPosition(a());let t=$(n.carryOver,e.time-o,0)/(n.type===2?h:1);if(!f.length)c.lerp(d,t);else{f.forEach((e,t)=>{let n=_[t],r=J.splineRingRadiusPlane?e.radius:0;y.set(e.x+r*Math.cos(n),e.y+r*Math.sin(n),0).applyQuaternion(l),v[t+1].lerpVectors(c,d,e.z).add(y)});let e=Math.min(1,Math.max(0,t)),n=0;for(;n<g.length-2&&e>g[n+1];)n++;let r=g[n+1]-g[n],i=r>0?(e-g[n])/r:1;C(n,b).multiplyScalar(r),C(n+1,x).multiplyScalar(r);let a=i*i,o=a*i;S.set(0,0,0).addScaledVector(v[n],2*o-3*a+1).addScaledVector(b,o-2*a+i).addScaledVector(v[n+1],-2*o+3*a).addScaledVector(x,o-a),c.copy(S)}return J.binderFollowTargetOrientation&&!n.followTargetOrientation&&l.identity(),s.compose(c,l,u).multiply(r)}}let r=n?up(e,n.bindPoint,n.bindTargetPoint,n.bindPointId,n.index):()=>e.matrixWorld,i=hp(e,t),a=new U,o=J.binderFollowTargetOrientation&&n&&!n.followTargetOrientation,s=n?.type===0?n.spring:void 0;if(s&&s.keys.some(e=>e.z!==1)){let t=new H,n=new V,c=new H,l=new H,u=e.time,d=-1;return()=>{r().decompose(t,n,c),d<0&&(l.copy(t),d=u);let f=Math.floor((e.time-d)*2+1e-6);for(let e=1;e<=f;e++){let n=Math.min(1,Math.max(0,$(s,d+e/2-u,1)));l.lerp(t,n)}return f>0&&(d+=f/2),o&&n.identity(),a.compose(l,n,c).multiply(i)}}if(o){let e=new H,t=new V,n=new H;return()=>(r().decompose(e,t,n),a.compose(e,t.identity(),n).multiply(i))}return()=>a.multiplyMatrices(r(),i)}var _p=class{schema;emitter;light;age=0;seed=new Wd;constructor(e,t,n){this.schema=e,this.emitter=t,this.light=n}};function vp(e,t){let n=e.schema.effectors[t.schema.effector];if(!n)return;if(n.type!==yd.PointLight&&n.type!==yd.RadialBlur&&!n.quake&&!n.dirLight){let t=Object.entries(yd).find(([,e])=>e===n.type)?.[0]??String(n.type);e.warnings.add(`effector #${n.index}: ${t} not supported`);return}n.radialBlur&&$(n.radialBlur.innerRadius,0,0)>0&&$(n.radialBlur.gradation,0,0)!==1&&e.warnings.add(`effector #${n.index}: radial blur — Gradation with Inner Radius not measured`);let r=new _p(n,t,n.type===yd.PointLight?e.backend.createLight(`effector ${n.index}`):null);e.effectors.push(r)}function yp(e,t){J.effectorEndsWithEmitter&&(e.effectors=e.effectors.filter(e=>e.emitter.alive?!0:(e.light?.dispose(),!1)));for(let n of e.effectors){n.age+=t;let{loopStart:r,loopEnd:i}=n.schema;!e.released&&i>r&&r>=0&&n.age>=i&&(n.age-=i-r)}}function bp(e,t){let n=t.emitter;return!e.hiddenEffectors.has(t.schema.index)&&!e.hiddenTimelines.has(n.timeline)&&!e.hiddenEmitters.has(n.schema.index)&&!n.ancestors.some(t=>e.hiddenEmitters.has(t))}function xp(e,t){let n=null,r=t.getWorldPosition(new H);for(let t of e.effectors){let i=t.schema.quake;if(!i||!bp(e,t))continue;let a=new H().setFromMatrixPosition(t.emitter.world).distanceTo(r),o=$(i.radiusIn,t.age,0),s=$(i.radiusOut,t.age,0),c=1;if(a>o){let e=s-o;c=e>0?vt.clamp((e-a)/e,0,1)**+$(i.attenuation,t.age,1):0}if(c*=e.fade,c<=0)continue;n??={position:new H,rotation:new H};let l=Qd(i.position,t.age,0,t.seed,0,Qf());n.position.x+=l[0]*c,n.position.y+=l[1]*c,n.position.z+=l[2]*c;let u=Qd(i.rotation,t.age,0,t.seed,3,Qf());n.rotation.x+=u[0]*c,n.rotation.y+=u[1]*c,n.rotation.z+=u[2]*c}return n}function Sp(e){if(!J.particleDirectionalLight||e.schema.directionalLightSource!==1)return;let t=new H,n=new H,r=new H,i=new B,a=e.effectors.find(t=>t.schema.dirLight&&bp(e,t));if(a){let e=a.schema.dirLight;ap(e.ambient,a.age,a.seed,i),n.set(i.x,i.y,i.z),ap(e.color,a.age,a.seed,i),r.set(i.x,i.y,i.z).multiplyScalar($(e.power,a.age,1));let o=Qd(e.rotation,a.age,0,a.seed,0,Qf()),s=new V().setFromEuler(new Mn(o[0],o[1],-o[2],Zf[a.schema.rotationOrder]??`XYZ`)),c=new V;a.emitter.world.decompose(new H,c,new H),t.set(0,0,-1).applyQuaternion(s).applyQuaternion(c).normalize()}for(let i of e.particles)i.schema.lit&&i.visual&&i.visual.setLight(t,n,r)}function Cp(e){return e.schema.particles.some(e=>e.dissolve&&e.dissolve.target&1)}function wp(e){let t=e.characterSkin;if(!J.dissolveOnCharacter||!t||!e.characterDissolve||!Cp(e))return;let n=e.particles.find(t=>t.schema.dissolve&&t.schema.dissolve.target&1&&!e.hidden(t)),r=e.backend.dissolveUniforms(t);n&&e.backend.patchDissolve(t.meshes,r);let i=n?.schema,a=i?.dissolve,o=i?.tc1?.enabled?i.tc1.textures[0]:void 0,s=o===void 0?void 0:e.textures[o];if(!n||!i||!a||!s&&!a.shape){r.dissolveOn.value=0;return}let c=s?e.backend.dissolveTexture(s):void 0,l=n.curveTime;if(r.dissolveOn.value=1,r.dissolveMap.value=c??null,r.dissolveTexOn.value=+!!c,r.dissolveMode.value=a.shape,a.shape&&Math.min(...Qd(i.scale,l,1,n.seed,8,Qf()).map(Math.abs))<1e-6){r.dissolveOn.value=0;return}if(a.shape){let e=n.follow?n.emitter.world.clone().multiply(new U().makeTranslation(n.offset)):n.spawnMatrix.clone(),t=Qd(i.rotation,l,0,n.seed,4,Qf());e.multiply(tp(Qd(i.position,l,0,n.seed,1,Qf()),t,Qd(i.scale,l,1,n.seed,8,Qf()),i.rotationOrder,new U,i.coordOrder)),n.travel.lengthSq()>0&&e.premultiply(new U().makeTranslation(n.travel)),r.dissolveShape.value.copy(e).invert();let o=Math.min(...Qd(i.scale,l,1,n.seed,8,Qf()).map(Math.abs)),s=$(a.endWidth,l,0);if(s>=2*o){r.dissolveOn.value=0;return}r.dissolveSoft.value=Math.max(.001,1.44*s/o)}r.dissolveAmount.value=$(a.erosion,l,0),r.dissolveWidth.value=Math.max(.001,$(a.midWidth,l,0)),r.dissolveMid.value=Math.min(.999,Math.max(.001,$(a.startWidth,l,0))),r.dissolveReverse.value=+!!a.reverse,r.dissolveGlow.value=$(a.intensity,l,1);let u=a.edgeScale,d=$(u.bri,l,1),f=$(u.sclR,l,1)*d,p=$(u.sclG,l,1)*$(u.sclB,l,1)*d;[a.startColor,a.midColor,a.endColor].forEach((e,t)=>{let i=ap(e,l,n.seed,new B);r.dissolveColors.value[t].set(i.x*f,i.y*p,i.z*d,Math.min(1,Math.max(0,i.w)))});let m=(e,t)=>{let r=i.uvSets[e];if(!r)return t.identity();let a=Qd(r.scale,l,1,n.seed,11,Qf()),o=Qd(r.scroll,l,0,n.seed,13,Qf()),s=$(r.rotation,l)*(J.uvRotationReversed?-1:1);return t.setUvTransform(o[0],o[1],a[0],a[1],s,0,0)};m(i.tc1.uvSet,r.dissolveUv.value);let h=i.distortion,g=h?.enabled?h.textures[0]:void 0,_=g===void 0?void 0:e.textures[g],v=_?e.backend.dissolveTexture(_):void 0;r.dissolveDistOn.value=+!!v,r.dissolveDistMap.value=v??null,r.dissolveDistPow.value=h&&v?$(h.power,l,0):0,h&&v&&m(1,r.dissolveDistUv.value)}var Tp=[`XYZ`,`YZX`,`ZXY`,`XZY`,`YXZ`,`ZYX`],Ep=e=>e.type===Y.Windmill||e.type===Y.Powder&&!e.simple;function Dp(e,t){let n=new V;return t.decompose(new H,n,new H),e.motion.clone().multiplyScalar(.5).applyQuaternion(n)}function Op(e,t,n,r){return $(e,n)+(J.rotationVelocityRandom?Zd(t,n,r):0)}function kp(e,t,n,r,i,a,o){let s=new H,c=new H,l=new H;e.extractBasis(s,c,l);let u=new H().setFromMatrixPosition(e),d=l,f=s.length();if(t===ld.X)d=s,f=l.length();else if(t===ld.Y)d=c;else if(t===ld.MoveDirection){if(a.hasLastWorld){let e=u.clone().sub(a.lastWorld);e.lengthSq()>1e-10&&a.moveDir.copy(e)}a.lastWorld.copy(u),a.hasLastWorld=!0;let e=a.moveDir.lengthSq()>0?a.moveDir:a.velocity.lengthSq()>0?a.velocity:null;if(!e)return{len:0,w:0,cap:new H(0,0,1)};d=e.clone().normalize().multiplyScalar(l.length())}let p=Math.abs(t===ld.X?o[2]:o[0]);p>1e-6&&(f/=p);let m=n*d.length(),h=d.lengthSq()>1e-12?d.clone().normalize():new H(0,0,1),g=i.clone().sub(u.clone().addScaledVector(h,m/2)),_=new H().crossVectors(h,g);_.lengthSq()<1e-12&&_.set(1,0,0),_.normalize();let v=new H().crossVectors(h,_).normalize();e.makeBasis(_,v,h).setPosition(u);let y=new H().crossVectors(_,g);return y.lengthSq()<1e-12&&y.copy(h),y.normalize(),y.dot(h)<0&&y.negate(),{len:m,w:r*f,cap:new H(0,y.dot(v),y.dot(h))}}function Ap(e,t,n){let r=(e,r,i,a)=>$(e,t,i)+Zd(r,t,n.get(a));return{angle:r(e.angle,e.angleRandom,Math.PI*2,16),radiusBegin:r(e.radiusBegin,e.radiusBeginRandom,1,17),radiusEnd:r(e.radiusEnd,e.radiusEndRandom,1,18),widthBegin:r(e.widthBegin,e.widthBeginRandom,1,19),widthEnd:r(e.widthEnd,e.widthEndRandom,1,20),heightBeginInner:r(e.heightBeginInner,e.heightBeginInnerRandom,0,21),heightEndInner:r(e.heightEndInner,e.heightEndInnerRandom,0,22),heightBeginOuter:r(e.heightBeginOuter,e.heightBeginOuterRandom,0,23),heightEndOuter:r(e.heightEndOuter,e.heightEndOuterRandom,0,24),intervalFactor:e.intervalFactor}}var jp=class e extends Yn{doc;textures;static lightIntensity=4;schema;warnings=new Set;fps;loop;loopDelay=0;maxParticles;rng;backend;setSceneDepth(e,t=1,n=1){this.backend.setSceneDepth(e,t,n)}setSceneColor(e,t=1,n=1){this.backend.setSceneColor(e,t,n)}viewportHeight=1080;groundY=0;playing=!1;time=0;released=!1;disabledTimelines=new Set;clipLog=[];scenario=[];scenarioRun=new Set;settledAt=null;finishedAt=null;kill=null;killed=!1;emitterSpawns=0;particleSpawns=0;timelineKills=new Map;bindPoints=new Map;caster=null;target=null;characterSkin=null;characterDissolve=!1;hiddenParticles=new Set;hiddenEmitters=new Set;hiddenTimelines=new Set;particleLayer;debug={wireframe:!1,emitters:!1};debugLayer;startedItems=new Set;timelineStarts=[];emitters=[];particles=[];effectors=[];hiddenEffectors=new Set;geometryCache=new Map;static async load(t,n,r={},i){let a=await n.load(t);if(!a)throw Error(`${t} not found`);let o=bu(a,t);return e.create(o,i??new ad(n),r)}static async create(t,n,r={}){let i=await Promise.all(t.textures.map(e=>n.get(e).catch(t=>(console.warn(`avfx: texture ${e}: ${String(t)}`),null))));return new e(t,i,r)}constructor(e,t,n={}){super(),this.doc=e,this.textures=t,this.name=e.source,this.schema=Nd(e),this.fps=n.fps??30,this.loop=n.loop??!1,this.maxParticles=n.maxParticles??4e3,this.rng=zd(n.seed??1);let r=new Xf(e.source);this.backend=r,this.particleLayer=r.particleLayer,this.debugLayer=r.debugLayer,t.forEach((t,n)=>{t||this.warnings.add(`texture #${n} ${e.textures[n]} missing`)})}setBindPoint(e,t){t?this.bindPoints.set(e,t):this.bindPoints.delete(e)}setCaster(e){this.caster=e?.object??null,this.bindPoints.clear();for(let[t,n]of e?.bindPoints??[])this.bindPoints.set(t,n);this.characterSkin=e?.skin??null,this.characterDissolve=e?.dissolve??!1}play(){this.playing=!0}pause(){this.playing=!1}restart(e){e!==void 0&&(this.rng=zd(e)),this.resetInstances(),this.emitterSpawns=0,this.particleSpawns=0,this.released=!1,this.kill=null,this.killed=!1,this.timelineKills.clear(),this.clipLog.length=0,this.scenarioRun.clear(),this.settledAt=this.finishedAt=null,this.time=0,this.playing=!0}playScenario(e,t){this.scenario=[...e].sort((e,t)=>e.frame-t.frame),this.lastFinishedFrame=null,this.restart(t)}release(){this.released=!0}trigger(e,t=0){let n=this.schema.triggers[e];return!n||!n.enabled||n.timeline<0?!1:this.playTimeline(n.timeline,t+n.start)}playTimelineAlone(e){return this.schema.timelines[e]?(this.resetInstances(),this.released=!1,this.kill=null,this.killed=!1,this.clipLog.length=0,this.time=0,this.schema.scheduler.forEach((e,t)=>this.startedItems.add(t)),this.scenario.forEach((e,t)=>this.scenarioRun.add(t)),this.playTimeline(e)):!1}playTimeline(e,t=0){return this.schema.timelines[e]?(this.timelineStarts.push({index:e,at:this.time+t,spawned:new Set}),this.playing=!0,!0):!1}timelineFade(e){let t=this.timelineKills.get(e);return t?t.frames>0?Math.max(0,1-(this.time-t.from)/t.frames):0:1}get fade(){return this.kill?this.kill.frames>0?Math.max(0,1-(this.time-this.kill.from)/this.kill.frames):0:1}runClip(e,t){switch(this.clipLog.push({timeline:e,type:t.type.trim(),frame:Math.round(this.time)}),t.type){case`ULLP`:this.release();break;case`END `:for(let e of this.emitters)e.stopped=!0;this.release();break;case`KILL`:{let e=J.killTargetsTimelines?t.ints.slice(1,4).filter(e=>e<-1).map(e=>-e-2):[];if(e.length){for(let n of e)this.timelineKills.set(n,{from:this.time,frames:Math.max(0,t.ints[0])});for(let t of this.emitters)e.includes(t.timeline)&&(t.stopped=!0)}else this.kill={from:this.time,frames:Math.max(0,t.ints[0])};break}case`REST`:this.restart();break;case`TRG `:this.trigger(t.ints[0]);break;case`RTRG`:{let[e,n]=[Math.min(t.ints[0],t.ints[1]),Math.max(t.ints[0],t.ints[1])];this.trigger(e+Math.floor(Vd()*(n-e+1)));break}default:this.warnings.add(`timeline #${e}: clip ${t.type.trim()} not supported`)}}stop(){this.resetInstances(),this.time=0,this.playing=!1}get stats(){return{frame:this.time,emitters:this.emitters.length,particles:this.particles.length}}get waitingForTrigger(){return this.timelineStarts.length===0&&!this.scenarioPending&&!this.schema.scheduler.some(e=>e.enabled&&this.schema.timelines[e.timeline])}get scenarioPending(){return this.scenario.some((e,t)=>!this.scenarioRun.has(t))}get allSpawned(){return this.timelineStarts.length!==0&&this.schema.scheduler.every((e,t)=>!e.enabled||this.startedItems.has(t))&&this.timelineStarts.every(e=>{let t=this.schema.timelines[e.index];return!t||this.disabledTimelines.has(e.index)||t.items.every((t,n)=>!t.enabled||e.spawned.has(n))})}get emittersDone(){return this.allSpawned&&this.emitters.length===0}get settled(){if(this.finished)return!0;if(this.kill||this.scenarioPending||!this.allSpawned)return!1;let e=!this.released,t=t=>{for(;t;t=t.parent){if(!t.alive)return!1;if(!Number.isFinite(t.lifetime)||(t.holdWhile?.()??!1)||e&&t.loops&&t.age>=t.schema.loopStart)return!0}return!1};return this.emitters.every(e=>!e.alive||t(e))&&this.particles.every(n=>{let r=n.schema,i=e&&r.loopEnd>r.loopStart&&r.loopStart>=0&&n.age>=r.loopStart;return!Number.isFinite(n.lifetime)||i||t(n.emitter)})}get settledFrame(){return this.settledAt}get finishedFrame(){return this.finishedAt}lastFinishedFrame=null;get finished(){return this.killed||this.emittersDone&&this.particles.length===0&&!this.scenarioPending}get heldUntilKill(){return this.schema.triggers.some(e=>e.enabled&&(this.schema.timelines[e.timeline]?.clips.some(e=>e.type===`KILL`)??!1))}restartKeepingParticles(){this.emitters=[],this.timelineStarts=[],this.startedItems.clear(),this.released=!1,this.clipLog.length=0,this.scenarioRun.clear(),this.settledAt=this.finishedAt=null,this.time=0}update(e,t){Hd(this.rng,()=>{if(this.backend.attach(this),this.camera=t,cp.cameraQuat=t.getWorldQuaternion(cp.cameraQuat??new V),this.playing){let t=e*this.fps;this.time+=t,this.step(t),this.loop&&J.loopKeepsParticles&&!this.finished&&this.heldUntilKill&&!this.kill&&this.emittersDone?this.restartKeepingParticles():(this.settled?this.settledAt??=this.time:this.settledAt=null,this.finished?this.finishedAt??=this.time:this.finishedAt=null,this.loop&&this.finishedAt!==null&&this.finishedAt+this.loopDelay<=this.time&&(this.lastFinishedFrame=this.finishedAt,this.restart()))}this.render(t),this.backend.renderDebug(this.debug,this.particles,this.emitters)})}dispose(){this.backend.restoreDissolve(),this.resetInstances(),this.backend.dispose();for(let e of this.geometryCache.values())e?.dispose();this.geometryCache.clear()}resetInstances(){for(let e of this.particles)this.releaseParticle(e);this.particles=[],this.timelineKills.clear();for(let e of this.effectors)e.light?.dispose();this.effectors=[],this.emitters=[],this.timelineStarts=[],this.startedItems.clear()}camera=null;clipFade(e,t,n){if(e.clipBase===1)return 1;let r=n.getWorldPosition(new H).distanceTo(new H().setFromMatrixPosition(t)),i=(e,t)=>t>e?vt.clamp((r-e)/(t-e),0,1):+(r>=e),a=1;return e.clipNear&&(a*=1-(1-i(e.clipNear[0],e.clipNear[1]))**1.5),e.clipFar&&(a*=(1-i(e.clipFar[0],e.clipFar[1]))**1.5),a}angleFade(e){if(!J.angleFade||!this.schema.angleFade.some(e=>e.enabled))return 1;let t=e.getWorldPosition(new H).applyMatrix4(this.matrixWorld.clone().invert()),n=[Math.acos(vt.clamp(t.y/Math.max(1e-6,t.length()),-1,1)),Math.abs(Math.atan2(t.x,t.z))],r=1;return this.schema.angleFade.forEach((e,t)=>{let i=n[t];e.enabled&&i!==void 0&&(i<=e.inner||(r*=e.outer>e.inner?Math.max(0,1-(i-e.inner)/(e.outer-e.inner)):0))}),r}step(e){if(this.killed)return;if(this.kill&&this.fade<=0){this.resetInstances(),this.kill=null,this.killed=!0;return}for(let[e]of this.timelineKills)if(!(this.timelineFade(e)>0)){this.timelineKills.delete(e);for(let t of this.particles)t.emitter.timeline===e&&this.releaseParticle(t);this.particles=this.particles.filter(t=>t.emitter.timeline!==e),this.emitters=this.emitters.filter(t=>t.timeline!==e)}this.scenario.forEach((e,t)=>{if(this.killed||this.scenarioRun.has(t)||this.time<e.frame)return;this.scenarioRun.add(t);let n=e.frame-this.time;e.action===`trigger`?this.trigger(e.index,n):e.action===`timeline`?this.playTimeline(e.index,n):this.release()}),this.schema.scheduler.forEach((e,t)=>{!e.enabled||this.startedItems.has(t)||this.time<e.start||(this.startedItems.add(t),this.timelineStarts.push({index:e.timeline,at:e.start,spawned:new Set}))});let t=new Set;for(let e of this.timelineStarts){let n=this.schema.timelines[e.index];if(!n||this.disabledTimelines.has(e.index))continue;let r=this.time-e.at;n.items.forEach((i,a)=>{if(!i.enabled||e.spawned.has(a)||r<i.start)return;e.spawned.add(a);let o=i.clip>=0?n.clips[i.clip]:void 0;o&&this.runClip(e.index,o);let s=this.schema.emitters[i.emitter];if(!s)return;let c=i.binder>=0?i.binder:n.binder,l=i.end>i.start?i.end-i.start:0,u=this.spawnEmitter(s,dp(this,c,e.at+i.start),l,r-i.start);u.timeline=e.index,u.binder=c,t.add(u),J.openTimelineItemHoldsEmitter&&i.end<0&&(u.holdWhile=()=>!this.released)})}this.updateMatrixWorld(!0);let n=[],r=[];for(let n of this.emitters){t.has(n)?n.stepStart=null:(n.stepWorld.copy(n.world),n.stepStart=n.age),t.has(n)||(n.age+=e*n.timeScale,n.totalAge+=e*n.timeScale);let i=n.schema.loopStart,a=n.schema.loopEnd;!this.released&&a>i&&i>=0&&n.age>=a&&n.wrap(a-i),n.moving&&n.alive&&this.moveEmitter(n,e),n.updateTransform(),n.stepStart!==null&&n.age>n.stepStart?n.motion.setFromMatrixPosition(n.world).sub(new H().setFromMatrixPosition(n.stepWorld)).divideScalar((n.age-n.stepStart)/(n.timeScale||1)):(n.curveMotion(n.motion),n.moving&&n.motion.add(n.velocity)),r.push(n)}for(;r.length;){let e=r.shift();for(let{item:t,count:n,at:r}of e.due(`particle`,64)){let i=this.schema.particles[t.target];if(!i)continue;J.infiniteParticlesOnce&&i.life.value<0&&!t.overrideLife&&e.stopItem(t),J.heldParticlesOnce&&i.loopEnd>i.loopStart&&i.loopStart>=0&&e.stopItem(t);let a=J.injectionAnglePerCreation?e.injected.get(t)??0:0;e.injected.set(t,a+n);let o=J.emitterRandomScope===`creation`?new Wd:void 0,s=e.enterAge(r);for(let s=0;s<n;s++){if(Vd()*100>=t.probability)continue;if(e.schema.childLimit>0&&e.liveChildren>=e.schema.childLimit)break;if(this.particles.length>=this.maxParticles){this.warnings.add(`particle cap ${this.maxParticles} reached`);break}let n=this.spawnParticle(i,t,e,a+s,o);this.ageNewborn(n,e.sinceAge(r)),this.particles.push(n),e.liveChildren++}s()}for(let{item:t,count:i,at:a}of e.due(`emitter`,8)){let o=this.schema.emitters[t.target];if(!o)continue;let s=J.injectionAnglePerCreation?e.injected.get(t)??0:0;e.injected.set(t,s+i);let c=t.injectionAngle,l=e.enterAge(a);for(let a=0;a<i;a++){if(J.childEmitterItemProps){if(Vd()*100>=t.probability)continue;if(e.schema.childLimit>0&&this.emitters.filter(t=>t.parent===e&&t.alive).length+n.filter(t=>t.parent===e).length>=e.schema.childLimit)break}let i=e.nextPoint(),l=e.injectionTurn(i,()=>Vd()),u=J.injectionAngleChildEmitters?s+a:0,d=u&&(c[0]||c[1]||c[2])?new U().makeRotationFromEuler(new Mn(c[0]*u,c[1]*u,c[2]*u,Zf[o.rotationOrder]??`XYZ`)):null,f=i||d?new U().makeTranslation(i?.position??new H):null;f&&d&&f.premultiply(d),f&&i&&J.cylinderPointFrame&&e.schema.type===od.CylinderModel?f.multiply(new U().makeRotationY(Math.atan2(i.normal.x,i.normal.z))):f&&i&&J.localDirectionChildEmitters&&t.localDirection===1&&i.normal.lengthSq()>1e-8&&f.multiply(ep(i.normal));let p=t.influenceCoord===hd.AllAlways||t.influenceCoord===hd.AllAlways_NoPosition||J.influenceUnknownFollows&&(t.influenceCoord===hd.Unknown||t.influenceCoord===hd.Unknown_NoPosition),m=J.withOptionsFollow&&(t.influenceCoord===hd.InitialPosition_WithOptions||t.influenceCoord===hd.WithOptions_NoPosition),h=new U().copy(e.world);f&&h.multiply(f),J.childEmitterItemProps&&t.influenceCoord===hd.InitialPosition&&h.compose(new H().setFromMatrixPosition(h),new V,new H().fromArray(this.schema.revised.scale));let g=new U,_=()=>f?g.multiplyMatrices(e.world,f):g.copy(e.world),v=new H,y=new V,b=new H,x=new U,S=t.inheritPosition&&t.influenceCoord!==hd.WithOptions_NoPosition,C=new cp(o,p?_:m?()=>{(S?_():h).decompose(v,y,b);let e=v.clone();return _().decompose(v,y,b),t.influenceCoord===hd.InitialPosition_WithOptions?y.identity():t.inheritRotation||y.identity(),x.compose(e,y,t.inheritScale?b:b.fromArray(this.schema.revised.scale))}:()=>h,J.inheritParentLife&&t.inheritParentLife&&Number.isFinite(e.lifetime)?Math.max(1,e.lifetime-e.age):0);if(t.generateDelayByOne&&t.generateDelay>0&&(C.age=C.totalAge=-a*t.generateDelay),C.posInWorld=t.influenceCoord===hd.InitialPosition_WithOptions,C.timeline=e.timeline,C.spawnOrder=e.spawnOrder,C.binder=e.binder,C.ancestors=[...e.ancestors,e.schema.index],C.parent=e,d&&(C.injectZ=c[2]*u),J.childEmitterItemProps){if(t.overrideLife&&o.life.value>0){let e=Math.max(1,t.overrideLifeValue+t.overrideLifeRandom*(Vd()*2-1));C.timeScale=o.life.value/e}t.influenceColor!==0&&(C.colorFrom={mode:t.influenceColor,initial:e.color.clone()}),t.startFrame>0&&!t.startFrameNullUpdate&&(C.age+=t.startFrame,C.totalAge+=t.startFrame)}if(J.emitterMotion&&i){let t=$(e.schema.injectionSpeed,e.age,0);if(t+=e.speedRandom(),J.velocityPerFrame||(t/=this.fps),J.injectionSpeedRevised){let e=this.schema.revised.scale;t*=(Math.abs(e[0])+Math.abs(e[1])+Math.abs(e[2]))/3}if(t){C.velocity.copy(i.normal).applyQuaternion(l??new V);let n=Qd(o.rotation,C.age,0,C.seed,4,Qf());(n[0]||n[1]||n[2])&&C.velocity.applyEuler(new Mn(n[0],n[1],n[2],Zf[o.rotationOrder]??`XYZ`)),d&&C.velocity.transformDirection(d),C.velocity.transformDirection(e.world).multiplyScalar(t),C.moving=!0,C.launch={velocity:C.velocity.clone(),quat:new V().setFromRotationMatrix(new U().extractRotation(h))}}}if(J.inheritParentVelocity&&t.inheritParentVelocity){let t=Dp(e,h);t.lengthSq()>0&&(C.velocity.add(t),C.moving=!0)}C.moving&&C.motion.copy(C.velocity),this.setupShape(C),C.updateTransform(),n.push(C),r.push(C)}l()}}this.emitters.push(...n);let i=new Set;if(J.carrierEmittersLive){for(let e of this.emitters)for(let t=e.parent;t;t=t.parent)i.add(t);for(let e of this.particles)if(e.follow||e.withOptions)for(let t=e.emitter;t;t=t.parent)i.add(t)}this.emitters=this.emitters.filter(e=>e.alive||n.includes(e)||i.has(e)),yp(this,e);for(let t of this.particles){if(t.fresh){t.fresh=!1;continue}this.move(t,e),t.cloud?.step(e,t.age<t.lifetime),t.age+=e,t.totalAge+=e;let n=t.schema.loopStart,r=t.schema.loopEnd;!this.released&&r>n&&n>=0&&t.age>=r&&(t.age-=r-n)}let a=this.particles.filter(e=>!e.alive);for(let e of a)this.releaseParticle(e),e.emitter.liveChildren--;a.length&&(this.particles=this.particles.filter(e=>e.alive))}ageNewborn(e,t){t>1e-6&&(this.move(e,t),e.cloud?.step(t,e.age<e.lifetime),e.age+=t,e.totalAge+=t)}moveEmitter(e,t){let n=e.schema,r=$(n.gravity,e.age,0)+Zd(n.gravityRandom,e.age,e.seed.get(13)),i=J.airResistanceIsSpeedScale?$(n.airResistance,e.age,1)+Zd(n.airResistanceRandom,e.age,e.seed.get(14)):1;if(J.emitterGravityNegativeDown?(e.fall+=r*t,e.travel.y+=e.fall*t):r&&(e.velocity.y+=(J.gravityDown?-r:r)*t),J.emitterVelocityAngle===`flight`&&e.launch&&!n.anyDirection&&J.emitterGravityNegativeDown){let t=n.velocityRandom.map(t=>$(t,e.age,0));if(t[0]||t[1]||t[2]){let r=e.launch.quat;e.velocity.copy(e.launch.velocity).applyQuaternion(r.clone().invert()).applyEuler(new Mn(t[0],t[1],t[2],Zf[n.rotationOrder]??`XYZ`)).applyQuaternion(r)}}e.travel.addScaledVector(e.velocity,i*t)}move(e,t){let n=e.schema,r=$(n.gravity,e.curveTime,0)+(J.gravityRandom?Zd(n.gravityRandom,e.curveTime,e.seed.get(25)):0);if(J.rotationVelocityTurnsFlight!==`off`&&(n.rotVelX||n.rotVelY||n.rotVelZ)){if(!e.spin){let t=(e,t)=>{let n=e.clone().normalize(),r=t.clone().addScaledVector(n,-t.dot(n));return r.lengthSq()<1e-8&&r.set(1,0,0).addScaledVector(n,-n.x),r.normalize(),new V().setFromRotationMatrix(new U().makeBasis(new H().crossVectors(r,n),r,n))};e.spin={launch:e.velocity.clone(),launchLocal:e.localVelocity.clone(),fall:new H,frame:t(e.velocity,new H(0,1,0).transformDirection(e.spawnMatrix)),frameLocal:t(e.localVelocity,new H(0,1,0))}}let i=J.rotationVelocityTurnsFlight,a=i===`angle`?1:e.totalAge*e.timeScale/(i===`second`?this.fps:1),o=e.curveTime,s=[Op(n.rotVelX,n.rotVelXRandom,o,e.seed.get(17))*a,Op(n.rotVelY,n.rotVelYRandom,o,e.seed.get(18))*a,Op(n.rotVelZ,n.rotVelZRandom,o,e.seed.get(19))*a],c;if(J.rotationVelocityFrame===`particle`){let t=Zf[n.rotationOrder]??`XYZ`,r=Qd(n.rotation,o,0,e.seed,4,Qf());c=new V().setFromEuler(new Mn(r[0]+s[0],r[1]+s[1],r[2]+s[2],t)).multiply(new V().setFromEuler(new Mn(r[0],r[1],r[2],t)).invert())}else c=new V().setFromEuler(new Mn(s[0],s[1],s[2],Tp[n.rotationOrder]??`XYZ`));let l=e.spin,u=e=>e.clone().multiply(c).multiply(e.clone().invert());r&&(l.fall.y+=(J.gravityDown?-r:r)*t),l.launch.lengthSq()>0?e.velocity.copy(l.launch).applyQuaternion(u(l.frame)).add(l.fall):e.velocity.copy(l.fall),l.launchLocal.lengthSq()>0&&e.localVelocity.copy(l.launchLocal).applyQuaternion(u(l.frameLocal))}else r&&(e.velocity.y+=(J.gravityDown?-r:r)*t);let i=n.airResistanceRandom,a=J.airResistanceIsSpeedScale?$(n.airResistance,e.curveTime,1)+Zd(i,e.curveTime,e.seed.get(12)):1;e.localFlight&&e.localVelocity.lengthSq()>0&&e.localTravel.addScaledVector(e.localVelocity,a*t),e.velocity.lengthSq()!==0&&e.travel.addScaledVector(e.velocity,a*t)}spawnEmitter(e,t,n,r){let i=new cp(e,t,n);return i.spawnOrder=this.emitterSpawns++,this.setupShape(i),i.age=i.totalAge=Math.max(0,r),this.emitters.push(i),vp(this,i),i}cameraShake(e){return Hd(this.rng,()=>xp(this,e))}radialBlurs(e){let t=[];for(let n of this.effectors){let r=n.schema.radialBlur;if(!r||!bp(this,n))continue;let i=new H().setFromMatrixPosition(n.emitter.world),a=new B(i.x,i.y,i.z,1).applyMatrix4(e.matrixWorldInverse).applyMatrix4(e.projectionMatrix);a.w<=0||t.push({center:new R(a.x/a.w/2+.5,a.y/a.w/2+.5),length:$(r.length,n.age,0),strength:$(r.strength,n.age,0)*this.fade,gradation:$(r.gradation,n.age,0),innerRadius:$(r.innerRadius,n.age,0),outerRadius:$(r.outerRadius,n.age,0)})}return t}renderEffectors(){let t=new B,n=new H;for(let r of this.effectors){let i=r.schema,a=r.emitter;if(!r.light)continue;let o=Qd(i.position,r.age,0,r.seed,1,Qf());n.set(o[0],o[1],o[2]).applyMatrix4(a.world),ap(i.color,r.age,r.seed,t);let s=Math.max(t.x,t.y,t.z,1e-6),c=$(i.distance,r.age,0),l=c>0?Math.max(0,$(i.color.bri,r.age,1))/c:1e6,u=i.attenuation+1;r.light.set(bp(this,r),n,t.x/s,t.y/s,t.z/s,e.lightIntensity*s*Math.max(0,t.w)*this.fade,l,u)}}hidden(e){let t=e.emitter;return t.stillMoveDirection||this.hiddenParticles.has(e.schema.index)||this.hiddenTimelines.has(t.timeline)||this.hiddenEmitters.has(t.schema.index)||t.ancestors.some(e=>this.hiddenEmitters.has(e))}setupShape(e){let t=e.schema;if(t.type===od.Model)e.points=xf(this.doc,t.modelIndex),e.points.length||this.warnings.add(`emitter #${t.index}: model ${t.modelIndex} has no emit vertices; point emitter`),t.injectionSpeed&&this.warnings.add(`emitter #${t.index}: injection speed taken as m/frame along emit-vertex normals (assumption)`);else if(t.type===od.SphereModel)e.points=ip(t).map(e=>({position:e,normal:e})),this.warnings.add(`emitter #${t.index}: Sphere Model points: UV sphere DivX × DivY, poles unless WithoutSingularPoint (from game tests)`);else if(t.type===od.CylinderModel)e.points=rp(t,0),this.warnings.add(`emitter #${t.index}: Cylinder Model points: DivX around radius Rad, DivY+1 rings evenly over Len, centred (from game tests)`);else if(J.coneModelRings&&t.type===od.ConeModel)e.coneDelta=Zd(t.injectionAngleRandom,0,Vd()),e.points=np(t,0,e.coneDelta),this.warnings.add(`emitter #${t.index}: Cone Model points: the axis point, then DivY rings up to Injection Angle from +Z, DivX each from −Y, at Radius (from game tests)`);else if(J.coneEmitter&&(t.type===od.Cone||t.type===od.ConeModel))this.warnings.add(`emitter #${t.index}: ${t.type===od.Cone?J.coneSizes?`Cone (starts between Inner and Outer Size along the direction, from a game test)`:`Cone (Inner/Outer Size not applied)`:`Cone Model (Divide X/Y, Radius not applied)`}: directions within Injection Angle of local +Z turned by Angle X/Y/Z (assumption)`);else if(t.type!==od.Point){let e=Object.entries(od).find(([,e])=>e===t.type)?.[0]??String(t.type);this.warnings.add(`emitter #${t.index}: shape ${e} not implemented; point emitter`)}}spawnParticle(e,t,n,r=0,i){let{visual:a,geometry:o,cloud:s,trail:c}=this.createMesh(e),l=e.type===Y.Decal||e.type===Y.DecalRing?-(2**51):0,u=this.particleSpawns++%2**22;a&&(a.order=l+e.drawPriority*2**46+n.spawnOrder%2**22*2**22+u+(this.overScene?2**51:0));let d=new lp(e,t,n,a,s,i);d.geometry=o,J.parameterLink&&t.parameterLink>=0&&t.parameterLink!==t.target&&(d.link=this.schema.particles[t.parameterLink]??null);let f=J.itemStartFrame&&t.startFrame>0&&!(J.startFrameNullUpdate&&t.startFrameNullUpdate),p=f&&!J.startFrameNullUpdate?t.startFrame:0;(J.startFrameNullUpdate?f:J.itemStartFrame&&t.startFrame>0&&!p)&&(d.age=d.totalAge=t.startFrame),n.startQuat||(n.startQuat=new V,d.spawnMatrix.decompose(new H,n.startQuat,new H)),d.trail=c,d.copyIndex=r;let m=n.nextPoint(),h=n.injectionTurn(m,e=>d.seed.get(26+e));if(d.localFlight=J.followPositionInEmitterSpace&&d.withOptions&&t.inheritPosition&&t.influenceCoord!==hd.WithOptions_NoPosition&&!!m,m){d.offset.copy(m.position),J.localDirectionFollowsNormal&&t.localDirection===1&&m.normal.lengthSq()>1e-8&&(d.normalFrame=ep(m.normal)),d.spawnMatrix.multiply(new U().makeTranslation(m.position));let e=n.schema.anyDirection&&J.emitterInjectionAngle===`emitterZ`?new H(0,0,1).applyQuaternion(h??new V):h?m.normal.clone().applyQuaternion(h):m.normal,r=n.schema,i=$(r.injectionSpeed,n.age,0);i+=n.speedRandom(),J.velocityPerFrame||(i/=this.fps),J.cylinderModelNoInjection&&r.type===od.CylinderModel&&(i=0);let a=()=>{let e=this.schema.revised,t=new V,r=new V,i=new H;return n.anchor().decompose(i,t,i.clone()),tp(e.position,e.rotation,e.scale,0,new U).decompose(i,r,i.clone()),t.multiply(r.invert())},o=!!i&&J.initialVelocityCasterTwice&&!n.parent,s=J.emitterVelocityRandom?new H(...r.velocityRandom.map((e,t)=>e?Zd(e,n.age,d.seed.get(20+t)):0)):new H;if(d.localFlight){if(i&&d.localVelocity.copy(e).multiplyScalar(i),s.lengthSq()>0&&d.localVelocity.add(s),o&&t.influenceCoord===hd.InitialPosition_WithOptions){let e=new V,t=new H;d.spawnMatrix.decompose(t,e,t.clone()),d.localVelocity.applyQuaternion(e.clone().invert().multiply(a()).multiply(e))}}else{if(i&&d.velocity.copy(e).transformDirection(d.spawnMatrix).multiplyScalar(i),s.lengthSq()>0){let e=s.length();d.velocity.add(s.transformDirection(d.spawnMatrix).multiplyScalar(e))}o&&t.influenceCoord===hd.InitialPosition&&!d.follow&&!d.withOptions&&d.velocity.applyQuaternion(a())}}if(J.inheritParentVelocity&&t.inheritParentVelocity&&d.velocity.add(Dp(n,d.spawnMatrix)),(J.initialPositionOnly&&t.influenceCoord===hd.InitialPosition||t.influenceCoord===hd.None)&&!d.follow&&!d.withOptions){let e=new H().setFromMatrixPosition(d.spawnMatrix);if(t.influenceCoord===hd.None){let t=n;for(;t.parent;)t=t.parent;let r=this.schema.revised,i=new U().multiplyMatrices(t.anchor(),hp(this,t.binder).invert()).multiply(tp([0,0,0],r.rotation,r.scale,0,new U));e.applyMatrix4(i.clone().invert()).setY(0).applyMatrix4(i)}d.spawnMatrix.compose(e,new V,new H().fromArray(this.schema.revised.scale))}for(let e=0;e<p;e++)this.move(d,1),d.age++,d.totalAge++;return d}releaseParticle(e){e.visual&&(e.visual.dispose(),e.cloud?.dispose(),e.trail?.dispose(),(e.schema.type===Y.DecalRing&&!e.geometry?.userData.decalBox||e.schema.type===Y.Disc||e.schema.type===Y.Laser)&&e.geometry?.dispose())}geometryFor(e){if(e.type===Y.Model||e.type===Y.LightModel)return this.geometryCache.has(e.modelIndex)||this.geometryCache.set(e.modelIndex,bf(this.doc,e.modelIndex)),(this.geometryCache.get(e.modelIndex)??null)||(this.warnings.add(`particle #${e.index}: model ${e.modelIndex} missing, drawn as quad`),nf());if(e.type===Y.Quad)return nf();if(e.type===Y.Polygon&&J.polygonAsQuad)return this.warnings.add(`particle #${e.index}: Polygon drawn as a quad, Count not applied (assumption)`),nf();if(e.type===Y.Powder)return nf();if(e.type===Y.Line&&e.simple)return this.warnings.add(`particle #${e.index}: Line simple animation drawn as screen streaks (approximation)`),nf();if(e.type===Y.Windmill)return this.warnings.add(`particle #${e.index}: Windmill — four camera-facing blades, 1 m per unit${e.windmillUvType===1?`, mirrored (UV type Mirror)`:``} (measured, tools/make_test_powder.ts)`),yf(e.windmillUvType);if(J.decalProjection&&(e.type===Y.Decal||e.type===Y.DecalRing))return of();if(e.type===Y.Decal)return this.warnings.add(`particle #${e.index}: Decal drawn as a flat quad on the ground plane (groundY), not projected onto other geometry (approximation); size, texture direction and box fade measured (tools/make_test_decal.ts)`),sf();if(e.type===Y.DecalRing)return this.warnings.add(`particle #${e.index}: DecalRing drawn as a flat ring on the ground plane (groundY), not projected onto other geometry (approximation); radii 0.5 ± Width, arc 2·acos(1 − 2·RF) about +Z, u / v and the box fade measured (tools/make_test_decal.ts ring / ringv)`),df(e.ringFan);if(e.type===Y.Laser)return gf();if(e.type===Y.Disc&&e.disc){let t=e.disc;return J.discUFromOuterEdge&&this.warnings.add(`particle #${e.index}: Disc — u from the outer edge (assumption)`),pf(t.countU,t.countV,J.discUFromOuterEdge,t.partsCount)}if(e.type===Y.Line&&!e.simple)return null;if(e.type===Y.ModelSkin&&J.modelSkinOnCharacter)return this.characterSkin&&e.auraTarget&1?(this.warnings.add(`particle #${e.index}: ModelSkin drawn on the character model (Aura Target Character), SEM/EEM/UV Point Density not applied (assumption)`),this.characterSkin.geometry):(this.warnings.add(`particle #${e.index}: ModelSkin — no ${e.auraTarget&1?`character model set`:`target model (Aura Target ${e.auraTarget})`}`),null);if(e.type===Y.Dissolve&&J.dissolveOnCharacter)return this.warnings.add(this.characterSkin&&e.dissolve&&e.dissolve.target&1?`particle #${e.index}: Dissolve on the character model: TC1 red < erosion is cut away, glow band End Color Width wide in particle colour × Intensity (assumption)`:`particle #${e.index}: Dissolve — no ${e.dissolve&&e.dissolve.target&1?`character model set`:`target model (Dissolve Target ${e.dissolve?.target})`}`),null;if(e.type!==Y.Parameter){let t=Object.entries(Y).find(([,t])=>t===e.type)?.[0]??String(e.type);this.warnings.add(`particle #${e.index}: type ${t} not drawn yet`)}return null}createMesh(e){let t=e.polyline?new Mf(e.polyline):null,n=t?t.geometry:this.geometryFor(e);if(!n)return{visual:null,geometry:null,cloud:null,trail:null};let r=t=>{if(!t?.enabled)return null;let n=t.textures[0],r=n===void 0?void 0:this.textures[n];return r?{layer:t,texture:r,frames:t.textures.map(e=>this.textures[e]??null)}:(n!==void 0&&this.warnings.add(`particle #${e.index}: texture #${n} missing`),null)},i=e.type===Y.Model||e.type===Y.LightModel,a=J.modelFresnelColor&&i&&e.fresnelType!==0&&!!(e.colorBegin||e.colorEnd);a&&e.fresnelType!==1&&this.warnings.add(`particle #${e.index}: fresnel type ${e.fresnelType} approximated as Camera (FrRt ignored)`);let o=J.lineColorAlongLength&&e.type===Y.Line&&!!(e.colorBegin||e.colorEnd),s=e.distortion,c=J.textureDistortion&&s?.enabled&&s.textures[0]!==void 0?this.textures[s.textures[0]]:void 0,l=s&&c?Object.assign({},s,{texture:c}):null;l&&!J.distortionHalfRange&&this.warnings.add(`particle #${e.index}: texture distortion — offset (rg·2−1)·DPow (distortionHalfRange off: not measured)`);let u=Ep(e),d=J.screenCopy&&!!e.tc1?.enabled&&e.tc1.screenCopy,f=e.palette,p=J.paletteAlpha&&f?.enabled&&f.texture>=0?this.textures[f.texture]??null:null;p&&this.warnings.add(`particle #${e.index}: texture palette — alpha × palette alpha at TC1 alpha + Offset, palette colour unused (assumption)`);let m={layer1:r(e.tc1),layer2:u?null:r(e.tc2),layer3:u?null:r(e.tc3),layer4:u?null:r(e.tc4),palette:p&&{texture:p,border:e.palette.border},distortion:l&&{layer:l,texture:l.texture},drawMode:e.drawMode,culling:e.culling,depthTest:e.depthTest&&!this.overScene,depthWrite:e.depthWrite&&!this.overScene,depthOffset:e.depthOffset,soft:J.softParticles&&e.softParticle&&!n?.userData.decalBox,softDistance:J.softFadeRangeFromHeader?this.schema.softFadeRange:void 0,decal:e.type===Y.Decal||e.type===Y.DecalRing,decalProject:n?.userData.decalBox?e.type===Y.DecalRing?`ring`:`decal`:void 0,vertexColors:i||!!t||e.type===Y.Disc,modelUvs:i&&!!n.getAttribute(`avfxUv2`),sprites:!!e.simple&&(e.type===Y.Powder||e.type===Y.Line),fresnel:a,lit:J.particleDirectionalLight&&e.lit&&this.schema.directionalLightSource===1?e.lightType:null,lineGradient:o,tc1White:J.textureLessTc1White&&(!e.tc1?.enabled||e.tc1.textures.length===0),tc1Off:!e.tc1?.enabled,screenCopy:d?{distorted:!!l&&l.targets[e.tc1.uvSet]===!0}:null},h=e.simple&&(e.type===Y.Powder||e.type===Y.Line)?new jf(e.simple,n,e.simple.injectionPosition===1?xf(this.doc,e.simple.injectionModel):[],e.type===Y.Line,J.simpleBindModelPath&&e.simple.injectionPosition===1&&e.simple.bindModel>=0&&e.simple.bindModel!==e.simple.injectionModel?xf(this.doc,e.simple.bindModel):[]):null,g=this.backend.createVisual(e,n,m,h);for(let e of g.notes)this.warnings.add(e);return{visual:g,geometry:n,cloud:h,trail:t}}get overScene(){let e=this.schema.drawLayer;return J.drawLayerOverScene&&(e===0||e===8||e===9)}render(e){this.renderEffectors(),Sp(this),wp(this);let t=e.getWorldQuaternion(new V),n=new H,r=new V,i=new H,a=new U,o=new U,s=new H,c=new V,l=new H,u=new B,d=new B,f=new B,p=new U,m=new U,h=new U,g=e instanceof ai?2*Math.tan(vt.degToRad(e.fov)/2)/e.zoom/Math.max(1,this.viewportHeight):0,_=this.angleFade(e);for(let v of this.particles){let y=v.visual;if(!y)continue;let b=v.schema;if(y.visible=!this.hidden(v),!y.visible)continue;let x=v.curveTime,S=Qd(b.position,x,0,v.seed,1,Qf()),C=Qd(b.rotation,x,0,v.seed,4,Qf()),w=new Mn(C[0],C[1],C[2],Zf[b.rotationOrder]??`XYZ`),T=v.totalAge*v.timeScale;C[0]+=Op(b.rotVelX,b.rotVelXRandom,x,v.seed.get(17))*T,C[1]+=Op(b.rotVelY,b.rotVelYRandom,x,v.seed.get(18))*T,C[2]+=Op(b.rotVelZ,b.rotVelZRandom,x,v.seed.get(19))*T;let E=v.item.injectionAngle,D=J.injectionAngleRotatesParticle?v.copyIndex:0,O=new Mn(E[0]*D,E[1]*D,E[2]*D,Zf[b.rotationOrder]??`XYZ`),k=!(J.treeBillboardQuadFixed&&b.type===Y.Quad&&b.rotationBase===ld.TreeBillboard)&&(b.type===Y.Powder&&!v.cloud||b.type===Y.Windmill||b.rotationBase===ld.ScreenBillboard||b.rotationBase===ld.CameraBillboard||b.rotationBase===ld.BillboardAxisY||b.rotationBase===ld.CameraBillboardAxisY||b.rotationBase===ld.MoveDirectionBillboard||b.rotationBase===ld.TreeBillboard),ee=!k&&J.injectionAngleTurnsPosition;!k&&!ee&&(C[0]+=O.x,C[1]+=O.y,C[2]+=O.z);let A=Qd(b.scale,x,1,v.seed,8,Qf());tp(S,C,A,b.rotationOrder,o,b.coordOrder);let te=v.link,ne=te?Qd(te.rotation,x,0,v.linkSeed,4,Qf()):null;te&&ne&&o.premultiply(tp(Qd(te.position,x,0,v.linkSeed,1,Qf()),ne,Qd(te.scale,x,1,v.linkSeed,8,Qf()),te.rotationOrder,new U,te.coordOrder)),v.normalFrame&&!k&&o.premultiply(v.normalFrame),ee&&(O.x||O.y||O.z)&&o.premultiply(p.makeRotationFromEuler(O)),(b.type===Y.Quad||b.type===Y.Polygon&&J.polygonAsQuad)&&(b.rotationBase===ld.X?o.multiply(p.makeRotationY(Math.PI/2)).multiply(m.makeRotationZ(Math.PI/2)):b.rotationBase===ld.Y&&o.multiply(p.makeRotationX(-Math.PI/2)));let j=J.emitterRandomScope===`emitter`?v.emitter.world:v.emitter.matrixFor(v.emitterSeed,h),M=j,N=new V;j.decompose(s,N,l),v.localFlight&&J.localFlightRotationAtSpawn&&!v.item.inheritRotation&&(J.withOptionsRotationAtEmitterStart&&v.emitter.startQuat?N.copy(v.emitter.startQuat):v.spawnMatrix.decompose(new H,N,new H),j.decompose(s,c,l),J.shapePointRotationNow||(M=new U().compose(s,N,l)));let re=J.localFlightUnscaled?new z().setFromMatrix4(new U().compose(new H,N,new H().fromArray(this.schema.revised.scale))):new z().setFromMatrix4(M);if(v.follow)a.copy(j),v.offset.lengthSq()>0&&a.multiply(new U().makeTranslation(v.offset)),a.multiply(o);else if(v.withOptions){let e=v.item,t=e.inheritPosition&&e.influenceCoord!==hd.WithOptions_NoPosition;(t?j:v.spawnMatrix).decompose(s,c,l);let n=s.clone();if(v.localFlight&&n.copy(v.offset).applyMatrix4(M).add(v.localTravel.clone().applyMatrix3(re)),j.decompose(s,c,l),!e.inheritRotation&&(c.identity(),J.inheritBinderRotation&&e.inheritBinderRotation)){let e=v.emitter;for(;e.parent;)e=e.parent;e.anchor().decompose(new H,c,new H)}a.compose(n,c,e.inheritScale?l:l.fromArray(this.schema.revised.scale)),!v.localFlight&&t&&v.offset.lengthSq()>0&&a.multiply(new U().makeTranslation(v.offset)),a.multiply(o)}else a.multiplyMatrices(v.spawnMatrix,o);if(v.travel.lengthSq()>0&&a.premultiply(new U().makeTranslation(v.travel)),J.moveDirectionAxisZ&&b.rotationBase===ld.MoveDirection&&b.type!==Y.Laser){if(a.decompose(s,c,l),v.hasLastWorld){let e=s.clone().sub(v.lastWorld);e.lengthSq()>1e-10&&v.moveDir.copy(e)}if(v.lastWorld.copy(s),v.hasLastWorld=!0,v.moveDir.lengthSq()>0){let e=v.moveDir.clone().normalize(),t=Math.abs(e.y)>.999?new H(1,0,0):new H(0,1,0),n=new H().crossVectors(t,e).normalize(),r=new H().crossVectors(e,n);c.setFromRotationMatrix(new U().makeBasis(n,r,e)).multiply(new V().setFromEuler(w)),a.compose(s,c,l)}}if(J.moveDirectionStreaks&&b.rotationBase===ld.MoveDirectionBillboard){a.decompose(s,c,l);let n=re,r=v.travel.clone();v.localFlight&&r.add(v.localTravel.clone().applyMatrix3(n));let i=r.clone().sub(v.lastFlight);v.lastFlight.copy(r);let o=J.moveDirectionFromFlight&&i.lengthSq()>1e-10?i:v.hasLastWorld?s.clone().sub(v.lastWorld):null;if(o&&o.lengthSq()>1e-10&&v.moveDir.copy(o),v.moveDir.lengthSq()===0){let e=v.velocity.clone();v.localFlight&&e.add(v.localVelocity.clone().applyMatrix3(n)),v.moveDir.copy(e.lengthSq()>0?e:new H(0,1,0))}v.lastWorld.copy(s),v.hasLastWorld=!0;let u=e.getWorldPosition(new H).sub(s).normalize(),d=v.moveDir.clone().addScaledVector(u,-v.moveDir.dot(u));d.lengthSq()<1e-12&&d.set(0,1,0).applyQuaternion(t),d.normalize();let f=new H().crossVectors(d,u).normalize();if(J.moveDirectionKeepsRotation){c.setFromRotationMatrix(new U().makeBasis(f,u.clone().negate(),d));let e=J.moveDirectionSpin?new Mn(w.x+Op(b.rotVelX,b.rotVelXRandom,x,v.seed.get(17)),w.y+Op(b.rotVelY,b.rotVelYRandom,x,v.seed.get(18)),w.z+Op(b.rotVelZ,b.rotVelZRandom,x,v.seed.get(19)),w.order):w;c.multiply(new V().setFromEuler(e))}else c.setFromRotationMatrix(new U().makeBasis(f,d,u));a.compose(s,c,l)}else if(k){a.decompose(s,c,l);let n=b.type===Y.Model||b.type===Y.LightModel||b.type===Y.Disc,r=n?new V().setFromEuler(new Mn(C[0],C[1],C[2],Zf[b.rotationOrder]??`XYZ`)):new V().setFromAxisAngle(new H(0,0,1),C[2]);if(n&&J.billboardModelKeepsEmitterRotation){let e=0;for(let t=v.emitter;t;t=t.parent)e+=t.rotZ+t.injectZ;e&&r.premultiply(new V().setFromAxisAngle(new H(0,0,1),e))}te&&ne&&r.premultiply(n?new V().setFromEuler(new Mn(ne[0],ne[1],ne[2],Zf[te.rotationOrder]??`XYZ`)):new V().setFromAxisAngle(new H(0,0,1),ne[2]));let i=b.rotationBase===ld.TreeBillboard&&(b.type===Y.Model||b.type===Y.LightModel);if(i){let t=new H(0,1,0).applyQuaternion(c).normalize(),n=e.getWorldPosition(new H).sub(s),r=n.addScaledVector(t,-n.dot(t));r.lengthSq()>1e-10&&(r.normalize(),c.setFromRotationMatrix(new U().makeBasis(new H().crossVectors(t,r),t,r)))}else if(b.rotationBase===ld.BillboardAxisY||b.rotationBase===ld.CameraBillboardAxisY||b.rotationBase===ld.TreeBillboard){let n=e.getWorldPosition(new H),r=new H(0,0,-1).applyQuaternion(t),i=J.billboardAxisYScreenParallel&&b.rotationBase===ld.BillboardAxisY?Math.atan2(-r.x,-r.z):Math.atan2(n.x-s.x,n.z-s.z);c.setFromAxisAngle(new H(0,1,0),i)}else if(b.rotationBase===ld.CameraBillboard){let n=e.getWorldPosition(new H).sub(s),r=new H(0,1,0).applyQuaternion(t),i=new H().crossVectors(r,n);n.lengthSq()>1e-10&&i.lengthSq()>1e-10?(n.normalize(),i.normalize(),c.setFromRotationMatrix(new U().makeBasis(i,new H().crossVectors(n,i),n))):c.copy(t)}else c.copy(t);i||c.multiply(new V().setFromEuler(O)).multiply(r),a.compose(s,c,l)}let ie=b.clipNear||b.clipFar?this.clipFade(b,a,e):1,ae=b.simple&&b.depthOffset<0?0:b.depthOffset,oe=ae?Math.min(ae,1)*e.getWorldPosition(new H).distanceTo(new H().setFromMatrixPosition(a)):null;if(b.type===Y.Laser){let t=$(b.lineLength,x,1)+Zd(b.lineLengthRandom,x,v.seed.get(14)),n=$(b.laserWidth,x,1)+Zd(b.laserWidthRandom,x,v.seed.get(16)),r=kp(a,b.rotationBase,t,n,e.getWorldPosition(new H),v,A);_f(v.geometry,r.len,r.w,r.cap)}let se=!!v.geometry?.userData.decalBox,ce=null;if(b.type===Y.DecalRing){let e=$(b.ringWidth,x,0)+Zd(b.ringWidthRandom,x,v.seed.get(14)),t=Math.max(0,.5+e),n=Math.max(0,Math.min(t,.5-e));se?ce=[n,t,Math.acos(Math.max(-1,Math.min(1,1-2*Math.max(0,Math.min(1,b.ringFan)))))]:ff(v.geometry,n,t)}b.disc&&(mf(v.geometry,Ap(b.disc,x,v.seed)),hf(v.geometry,b.disc.colorInner?ap(b.disc.colorInner,x,v.seed,d):d.set(1,1,1,1),b.disc.colorOuter?ap(b.disc.colorOuter,x,v.seed,f):f.set(1,1,1,1)));let le=1;if(se)y.setDecalProjection(a,e,this.groundY,ce);else if(b.type===Y.Decal||b.type===Y.DecalRing){a.decompose(s,c,l);let e=l.y*1/2;if(Math.abs(s.y-this.groundY)<=e)le=Math.min(1,5*(.5-Math.abs(s.y-this.groundY)/(2*e))),s.y=this.groundY,a.compose(s,c,l);else{y.visible=!1;continue}}if(v.trail&&b.polyline){let t=b.polyline;a.decompose(s,c,l);let n=new U;if(J.polylineInEffectSpace){let e=v.emitter;for(;e.parent;)e=e.parent;n.copy(e.anchor())}let r=n.clone().invert();if(t.createType===1)v.trail.softness=$(t.softness,x,0),v.trail.historyFrames=t.pointCount/2+2,v.trail.maxLength=$(t.length,x,1/0),v.trail.record(v.totalAge,s.clone().applyMatrix4(r));else if(J.polylineConnectTarget&&t.connectTarget){let e=this.schema.binders[v.emitter.binder],n=e?.goal&&(e.type===1||e.type===2||e.type===4),i=t.connectReverse?n?up(this,e.bindPoint,e.bindTargetPoint,e.bindPointId,e.index)():(this.caster??this).matrixWorld:n?up(this,e.goal.bindPoint,e.goal.bindTargetPoint,e.goal.bindPointId,e.index)():(this.target??this.caster??this).matrixWorld,a=s.clone(),o=new H().setFromMatrixPosition(i),c=Math.max(2,t.pointCount),l=[];for(let e=0;e<c;e++)l.push(a.clone().lerp(o,e/(c-1)).applyMatrix4(r));v.trail.setPoints(l)}else{let e=$(t.length,x,1),n=new H(0,1,0);J.polylineAxisFromRotationBase&&b.rotationBase===ld.X&&n.set(1,0,0),J.polylineAxisFromRotationBase&&b.rotationBase===ld.Z&&n.set(0,0,1);let i=[];for(let o=0;o<Math.max(2,t.pointCount);o++)i.push(n.clone().multiplyScalar(e*o/(Math.max(2,t.pointCount)-1)).applyMatrix4(a).applyMatrix4(r));v.trail.setPoints(i)}let i=e=>e?ap(e,x,v.seed,new B):new B(1,1,1,1),o=this.schema.revised.scale.map(Math.abs),u={x:o[0],y:o[1],z:o[2],xy:(o[0]+o[1])/2,mean:(o[0]+o[1]+o[2])/3,max:Math.max(...o)},d=J.polylineInEffectSpace?1:u[J.polylineWidthAxis]??1,f=t.notBillboard?new H(+(t.notBillboardAxis===0),+(t.notBillboardAxis===1),+(t.notBillboardAxis===2)).transformDirection(a).transformDirection(r):void 0;v.trail.build(e.getWorldPosition(new H).applyMatrix4(r),{width:($(t.width,x,1)+Zd(t.widthRandom,x,v.seed.get(16)))*d,begin:$(t.widthBegin,x,1),center:$(t.widthCenter,x,1),end:$(t.widthEnd,x,1)},{begin:i(t.colorBegin),center:i(t.colorCenter),end:i(t.colorEnd),edgeBegin:i(t.colorEdgeBegin),edgeCenter:i(t.colorEdgeCenter),edgeEnd:i(t.colorEdgeEnd)},f),a.copy(n)}if(J.collisionFreeze&&b.collision===2&&(a.decompose(s,c,l),!v.stuck&&s.y<0&&(v.stuck=s.clone().setY(0)),v.stuck&&a.compose(v.stuck,c,l)),v.cloud){a.decompose(s,c,l);let o=$(b.lineLength,x,1)+Zd(b.lineLengthRandom,x,v.seed.get(14));v.emitter.world.decompose(n,r,i),v.cloud.render(a,t,l,e,g,o,this.schema.revised.scale,r),a.identity()}if(b.type===Y.ModelSkin&&this.characterSkin&&(this.characterSkin.object.updateMatrixWorld(),a.copy(this.characterSkin.object.matrixWorld)),y.setMatrix(a),ap(b.color,x,v.seed,u,J.brightnessScalesAlpha),te){let e=ap(te.color,x,v.linkSeed,d,J.brightnessScalesAlpha);u.set(u.x*e.x,u.y*e.y,u.z*e.z,u.w*e.w)}u.w*=this.fade*this.timelineFade(v.emitter.timeline)*_*ie*le;let ue=this.schema.revised.color;if(u.x*=ue[0],u.y*=ue[1],u.z*=ue[2],v.item.influenceColor!==0){let e=v.emitter.color;u.set(u.x*e.x,u.y*e.y,u.z*e.z,u.w*e.w)}if(y.setColor(u.x,u.y,u.z,u.w),oe!==null&&y.setDepthOffset(oe),y.useScene(e,b.softParticle),(b.colorBegin||b.colorEnd)&&(b.colorBegin?ap(b.colorBegin,x,v.seed,d):d.set(1,1,1,1),b.colorEnd?ap(b.colorEnd,x,v.seed,f):f.set(1,1,1,1),y.setColorEnds(d,f,$(b.fresnelCurve,x,1))),y.frameCount>1&&b.tc1){let e=$(b.tc1.texN,x,0)+$(b.tc1.texNRandom,x,0)*v.seed.get(15);y.setFrame(Math.min(y.frameCount-1,Math.max(0,Math.floor(e))))}for(let[e,t]of[[1,b.tc1],[2,b.tc2],[3,b.distortion],[4,b.tc3],[5,b.tc4]]){if(e!==3&&Ep(b))continue;let n=t?.enabled?b.uvSets[t.uvSet]:void 0;if(!n)continue;let r=Qd(n.scale,x,1,v.seed,11,Qf()),i=Qd(n.scroll,x,0,v.seed,13,Qf()),a=$(n.rotation,x)*(J.uvRotationReversed?-1:1);y.setUv(e,r[0],r[1],i[0],i[1],a)}b.distortion?.enabled&&J.textureDistortion&&y.setDistortPower($(b.distortion.power,x,0)),b.palette?.enabled&&y.setPaletteOffset($(b.palette.offset,x,0)+Zd(b.palette.offsetRandom,x,v.seed.get(13)))}}};function Mp(){let e=G.tonemapping_pars_fragment;if(e.includes(`/* game tone mapping */`))return!0;let t=e.replace(`vec3 CustomToneMapping( vec3 color ) { return color; }`,`vec3 CustomToneMapping( vec3 color ) {
	/* game tone mapping */
	color *= toneMappingExposure;
	float y = max( dot( color, vec3( 0.29891, 0.58661, 0.11448 ) ), 1e-5 );
	return color * ( 1.0 - exp( -y ) ) / y;
}`);return t===e?(console.warn(`avfx: three.js CustomToneMapping is not the stub; the game tone mapping is not installed`),!1):(G.tonemapping_pars_fragment=t,!0)}var Np=24,Pp=class{material=new ei({uniforms:{map:{value:null},center:{value:new R(.5,.5)},len:{value:0},strength:{value:0},display:{value:1},innerRadius:{value:0},outerRadius:{value:0},gradation:{value:1},useMask:{value:1},inputDisplay:{value:0}},vertexShader:`
      varying vec2 vUv;
      void main() {
        vUv = uv;
        gl_Position = vec4(position.xy, 0.0, 1.0);
      }`,fragmentShader:`
      uniform sampler2D map;
      uniform vec2 center;
      uniform float len;
      uniform float strength;
      uniform float display;
      uniform float innerRadius;
      uniform float outerRadius;
      uniform float gradation;
      uniform float useMask;
      uniform float inputDisplay;
      varying vec2 vUv;
      vec3 srgbEncode(vec3 c) {
        c = max(c, 0.0);
        return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(0.0031308, c));
      }
      vec3 srgbDecode(vec3 c) {
        return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
      }
      // Into the space the blur averages in (display or linear) and back to linear.
      vec3 toWork(vec3 v) {
        if (inputDisplay > 0.5) return display > 0.5 ? v : srgbDecode(v);
        return display > 0.5 ? srgbEncode(v) : v;
      }
      vec3 toLinear(vec3 w) {
        return display > 0.5 ? srgbDecode(w) : w;
      }
      void main() {
        vec4 base = texture2D(map, vUv);
        vec3 sum = vec3(0.0);
        for (int i = 0; i < ${Np}; i++) {
          float s = (float(i) + 0.5) / ${Np}.0;
          sum += toWork(texture2D(map, center + (vUv - center) * (1.0 - len * s)).rgb);
        }
        // DonutMerge.shcd: radii ri = IRad / 2, ro = ORad / 2 in UV of the screen; ORad 0 — no blur.
        float mask = 1.0;
        if (useMask > 0.5) {
          vec2 p = vUv - center;
          float g = gradation > 0.0 ? 0.5 / gradation : 1e6;
          float inner = innerRadius > 0.0 ? 1.0 + g * (dot(p, p) / (0.25 * innerRadius * innerRadius) - 1.0) : 1e6;
          float outer = outerRadius > 0.0 ? 0.5 + g * (1.0 - dot(p, p) / (0.25 * outerRadius * outerRadius)) : -1e6;
          mask = clamp(min(inner, outer), 0.0, 1.0);
        }
        gl_FragColor = vec4(toLinear(mix(toWork(base.rgb), sum / ${Np}.0, clamp(strength * mask, 0.0, 1.0))), base.a);
        // Linear colour out; converted only when drawn to the canvas.
        #include <colorspace_fragment>
      }`,depthTest:!1,depthWrite:!1});quad=new Ur(new bi(2,2),this.material);camera=new ji;targets=[];render(e,t,n,r,i=!1){let a=t.image.width,o=t.image.height,s=t,c=n.length?n:[{center:new R(.5,.5),length:0,strength:0,gradation:1,innerRadius:0,outerRadius:0}];c.forEach((t,n)=>{let l=n===c.length-1,u=r;if(!l){let e=this.targets[n%2]??=new Wt(a,o,{type:y});(e.width!==a||e.height!==o)&&e.setSize(a,o),u=e}let d=this.material.uniforms;d.map.value=s,d.inputDisplay.value=n===0&&i?1:0,d.center.value.copy(t.center),d.len.value=t.length,d.strength.value=t.strength,d.display.value=+!!J.radialBlurDisplaySpace,d.useMask.value=+!!J.radialBlurRadiusMask,d.innerRadius.value=t.innerRadius,d.outerRadius.value=t.outerRadius,d.gradation.value=J.radialBlurGradation&&!(t.innerRadius>0)?t.gradation:1,e.setRenderTarget(u),e.render(this.quad,this.camera),u&&(s=u.texture)}),e.setRenderTarget(null)}dispose(){this.material.dispose(),this.quad.geometry.dispose();for(let e of this.targets)e.dispose()}},Fp=class{resolver;textures;docs=new Map;constructor(e){this.resolver=e,this.textures=new ad(e)}document(e){let t=wu(e),n=this.docs.get(t);return n||(n=this.resolver.load(e).then(t=>{if(!t)throw Error(`${e} not found`);return bu(t,e)}),n.catch(()=>this.docs.delete(t)),this.docs.set(t,n)),n}async preload(e){await Promise.all(e.map(async e=>{let t=await this.document(e);await Promise.all(t.textures.map(e=>this.textures.get(e).catch(()=>null)))}))}async create(e,t={}){let n=typeof e==`string`?await this.document(e):e;return jp.create(n,this.textures,t)}forget(e){for(let t of e)this.docs.delete(wu(t));this.textures.forget(e),this.resolver.forget?.(e)}dispose(){this.textures.dispose(),this.docs.clear()}},Ip=class{effects=new Set;applyCameraShake=!0;drawingBufferSize=new R;depthTarget=new Wt(1,1,{depthTexture:new aa(1,1)});hostDepth=null;frameCopy=new Dc(1,1);radialBlurPass=new Pp;camera=null;shakeFrom=null;add(e){this.effects.add(e)}remove(e){this.effects.delete(e)}render(e,t,n,r){this.beforeRender(e,t,n,r),e.render(t,n),this.afterRender(e)}beforeRender(e,t,n,r){this.camera=n;let i=this.applyCameraShake?this.cameraShake(n):null;if(this.shakeFrom=i?{position:n.position.clone(),quaternion:n.quaternion.clone()}:null,i&&(n.translateX(i.position.x).translateY(i.position.y).translateZ(i.position.z),n.rotateX(i.rotation.x).rotateY(i.rotation.y).rotateZ(i.rotation.z),n.updateMatrixWorld()),!this.effects.size)return;let a=this.drawingBufferSize;e.getDrawingBufferSize(a);let o=this.depthTarget;if(!this.hostDepth){(o.width!==a.x||o.height!==a.y)&&o.setSize(a.x,a.y);let r=[...this.effects].map(e=>[e,e.particleLayer.visible]);for(let[e]of r)e.particleLayer.visible=!1;e.setRenderTarget(o),e.render(t,n),e.setRenderTarget(null);for(let[e,t]of r)e.particleLayer.visible=t}let s=this.hostDepth;for(let e of this.effects)e.viewportHeight=a.y,s?(e.setSceneDepth(s.depth,s.width,s.height),e.setSceneColor(s.color,s.width,s.height)):(e.setSceneDepth(o.depthTexture,a.x,a.y),e.setSceneColor(o.texture,a.x,a.y)),e.update(r,n)}afterRender(e){let t=this.camera?this.radialBlurs(this.camera):[];if(t.length){let n=this.drawingBufferSize,r=this.frameCopy;(r.image.width!==n.x||r.image.height!==n.y)&&(r.dispose(),r=this.frameCopy=new Dc(n.x,n.y),r.minFilter=r.magFilter=l),e.copyFramebufferToTexture(r),this.radialBlurPass.render(e,r,t,null,!0)}let n=this.shakeFrom;n&&this.camera&&(this.camera.position.copy(n.position),this.camera.quaternion.copy(n.quaternion),this.camera.updateMatrixWorld()),this.shakeFrom=null}setSceneDepth(e,t=null,n=1,r=1){this.hostDepth=e?{depth:e,color:t,width:n,height:r}:null}cameraShake(e){let t=null;for(let n of this.effects){let r=n.cameraShake(e);r&&(t?(t.position.add(r.position),t.rotation.add(r.rotation)):t=r)}return t}radialBlurs(e){return[...this.effects].flatMap(t=>t.radialBlurs(e))}dispose(){this.depthTarget.dispose(),this.frameCopy.dispose(),this.radialBlurPass.dispose(),this.effects.clear()}};function Lp(e,t=!1){let n=e[0].index!==null,r=new Set(Object.keys(e[0].attributes)),i=new Set(Object.keys(e[0].morphAttributes)),a={},o={},s=e[0].morphTargetsRelative,c=new jr,l=0;for(let u=0;u<e.length;++u){let d=e[u],f=0;if(n!==(d.index!==null))return console.error(`THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index `+u+`. All geometries must have compatible attributes; make sure index attribute exists among all geometries, or in none of them.`),null;for(let e in d.attributes){if(!r.has(e))return console.error(`THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index `+u+`. All geometries must have compatible attributes; make sure "`+e+`" attribute exists among all geometries, or in none of them.`),null;a[e]===void 0&&(a[e]=[]),a[e].push(d.attributes[e]),f++}if(f!==r.size)return console.error(`THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index `+u+`. Make sure all geometries have the same number of attributes.`),null;if(s!==d.morphTargetsRelative)return console.error(`THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index `+u+`. .morphTargetsRelative must be consistent throughout all geometries.`),null;for(let e in d.morphAttributes){if(!i.has(e))return console.error(`THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index `+u+`.  .morphAttributes must be consistent throughout all geometries.`),null;o[e]===void 0&&(o[e]=[]),o[e].push(d.morphAttributes[e])}if(t){let e;if(n)e=d.index.count;else if(d.attributes.position!==void 0)e=d.attributes.position.count;else return console.error(`THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index `+u+`. The geometry must have either an index or a position attribute`),null;c.addGroup(l,e,u),l+=e}}if(n){let t=0,n=[];for(let r=0;r<e.length;++r){let i=e[r].index;for(let e=0;e<i.count;++e)n.push(i.getX(e)+t);t+=e[r].attributes.position.count}c.setIndex(n)}for(let e in a){let t=Rp(a[e]);if(!t)return console.error(`THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the `+e+` attribute.`),null;c.setAttribute(e,t)}for(let e in o){let t=o[e][0].length;if(t===0)break;c.morphAttributes=c.morphAttributes||{},c.morphAttributes[e]=[];for(let n=0;n<t;++n){let t=[];for(let r=0;r<o[e].length;++r)t.push(o[e][r][n]);let r=Rp(t);if(!r)return console.error(`THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the `+e+` morphAttribute.`),null;c.morphAttributes[e].push(r)}}return c}function Rp(e){let t,n,r,i=-1,a=0;for(let o=0;o<e.length;++o){let s=e[o];if(t===void 0&&(t=s.array.constructor),t!==s.array.constructor)return console.error(`THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.array must be of consistent array types across matching attributes.`),null;if(n===void 0&&(n=s.itemSize),n!==s.itemSize)return console.error(`THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.itemSize must be consistent across matching attributes.`),null;if(r===void 0&&(r=s.normalized),r!==s.normalized)return console.error(`THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.normalized must be consistent across matching attributes.`),null;if(i===-1&&(i=s.gpuType),i!==s.gpuType)return console.error(`THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.gpuType must be consistent across matching attributes.`),null;a+=s.count*n}let o=new t(a),s=new br(o,n,r),c=0;for(let t=0;t<e.length;++t){let r=e[t];if(r.isInterleavedBufferAttribute){let e=c/n;for(let t=0,i=r.count;t<i;t++)for(let i=0;i<n;i++){let n=r.getComponent(t,i);s.setComponent(t+e,i,n)}}else o.set(r.array,c);c+=r.count*n}return i!==void 0&&(s.gpuType=i),s}var zp={type:`change`},Bp={type:`start`},Vp={type:`end`},Hp=new Sn,Up=new mi,Wp=Math.cos(70*vt.DEG2RAD),Gp=new H,Kp=2*Math.PI,qp={NONE:-1,ROTATE:0,DOLLY:1,PAN:2,TOUCH_ROTATE:3,TOUCH_PAN:4,TOUCH_DOLLY_PAN:5,TOUCH_DOLLY_ROTATE:6},Jp=1e-6,Yp=class extends tu{constructor(e,r=null){super(e,r),this.state=qp.NONE,this.enabled=!0,this.target=new H,this.cursor=new H,this.minDistance=0,this.maxDistance=1/0,this.minZoom=0,this.maxZoom=1/0,this.minTargetRadius=0,this.maxTargetRadius=1/0,this.minPolarAngle=0,this.maxPolarAngle=Math.PI,this.minAzimuthAngle=-1/0,this.maxAzimuthAngle=1/0,this.enableDamping=!1,this.dampingFactor=.05,this.enableZoom=!0,this.zoomSpeed=1,this.enableRotate=!0,this.rotateSpeed=1,this.enablePan=!0,this.panSpeed=1,this.screenSpacePanning=!0,this.keyPanSpeed=7,this.zoomToCursor=!1,this.autoRotate=!1,this.autoRotateSpeed=2,this.keys={LEFT:`ArrowLeft`,UP:`ArrowUp`,RIGHT:`ArrowRight`,BOTTOM:`ArrowDown`},this.mouseButtons={LEFT:t.ROTATE,MIDDLE:t.DOLLY,RIGHT:t.PAN},this.touches={ONE:n.ROTATE,TWO:n.DOLLY_PAN},this.target0=this.target.clone(),this.position0=this.object.position.clone(),this.zoom0=this.object.zoom,this._domElementKeyEvents=null,this._lastPosition=new H,this._lastQuaternion=new V,this._lastTargetPosition=new H,this._quat=new V().setFromUnitVectors(e.up,new H(0,1,0)),this._quatInverse=this._quat.clone().invert(),this._spherical=new Ql,this._sphericalDelta=new Ql,this._scale=1,this._panOffset=new H,this._rotateStart=new R,this._rotateEnd=new R,this._rotateDelta=new R,this._panStart=new R,this._panEnd=new R,this._panDelta=new R,this._dollyStart=new R,this._dollyEnd=new R,this._dollyDelta=new R,this._dollyDirection=new H,this._mouse=new R,this._performCursorZoom=!1,this._pointers=[],this._pointerPositions={},this._controlActive=!1,this._onPointerMove=Zp.bind(this),this._onPointerDown=Xp.bind(this),this._onPointerUp=Qp.bind(this),this._onContextMenu=am.bind(this),this._onMouseWheel=tm.bind(this),this._onKeyDown=nm.bind(this),this._onTouchStart=rm.bind(this),this._onTouchMove=im.bind(this),this._onMouseDown=$p.bind(this),this._onMouseMove=em.bind(this),this._interceptControlDown=om.bind(this),this._interceptControlUp=sm.bind(this),this.domElement!==null&&this.connect(),this.update()}connect(){this.domElement.addEventListener(`pointerdown`,this._onPointerDown),this.domElement.addEventListener(`pointercancel`,this._onPointerUp),this.domElement.addEventListener(`contextmenu`,this._onContextMenu),this.domElement.addEventListener(`wheel`,this._onMouseWheel,{passive:!1}),this.domElement.getRootNode().addEventListener(`keydown`,this._interceptControlDown,{passive:!0,capture:!0}),this.domElement.style.touchAction=`none`}disconnect(){this.domElement.removeEventListener(`pointerdown`,this._onPointerDown),this.domElement.removeEventListener(`pointermove`,this._onPointerMove),this.domElement.removeEventListener(`pointerup`,this._onPointerUp),this.domElement.removeEventListener(`pointercancel`,this._onPointerUp),this.domElement.removeEventListener(`wheel`,this._onMouseWheel),this.domElement.removeEventListener(`contextmenu`,this._onContextMenu),this.stopListenToKeyEvents(),this.domElement.getRootNode().removeEventListener(`keydown`,this._interceptControlDown,{capture:!0}),this.domElement.style.touchAction=`auto`}dispose(){this.disconnect()}getPolarAngle(){return this._spherical.phi}getAzimuthalAngle(){return this._spherical.theta}getDistance(){return this.object.position.distanceTo(this.target)}listenToKeyEvents(e){e.addEventListener(`keydown`,this._onKeyDown),this._domElementKeyEvents=e}stopListenToKeyEvents(){this._domElementKeyEvents!==null&&(this._domElementKeyEvents.removeEventListener(`keydown`,this._onKeyDown),this._domElementKeyEvents=null)}saveState(){this.target0.copy(this.target),this.position0.copy(this.object.position),this.zoom0=this.object.zoom}reset(){this.target.copy(this.target0),this.object.position.copy(this.position0),this.object.zoom=this.zoom0,this.object.updateProjectionMatrix(),this.dispatchEvent(zp),this.update(),this.state=qp.NONE}update(e=null){let t=this.object.position;Gp.copy(t).sub(this.target),Gp.applyQuaternion(this._quat),this._spherical.setFromVector3(Gp),this.autoRotate&&this.state===qp.NONE&&this._rotateLeft(this._getAutoRotationAngle(e)),this.enableDamping?(this._spherical.theta+=this._sphericalDelta.theta*this.dampingFactor,this._spherical.phi+=this._sphericalDelta.phi*this.dampingFactor):(this._spherical.theta+=this._sphericalDelta.theta,this._spherical.phi+=this._sphericalDelta.phi);let n=this.minAzimuthAngle,r=this.maxAzimuthAngle;isFinite(n)&&isFinite(r)&&(n<-Math.PI?n+=Kp:n>Math.PI&&(n-=Kp),r<-Math.PI?r+=Kp:r>Math.PI&&(r-=Kp),n<=r?this._spherical.theta=Math.max(n,Math.min(r,this._spherical.theta)):this._spherical.theta=this._spherical.theta>(n+r)/2?Math.max(n,this._spherical.theta):Math.min(r,this._spherical.theta)),this._spherical.phi=Math.max(this.minPolarAngle,Math.min(this.maxPolarAngle,this._spherical.phi)),this._spherical.makeSafe(),this.enableDamping===!0?this.target.addScaledVector(this._panOffset,this.dampingFactor):this.target.add(this._panOffset),this.target.sub(this.cursor),this.target.clampLength(this.minTargetRadius,this.maxTargetRadius),this.target.add(this.cursor);let i=!1;if(this.zoomToCursor&&this._performCursorZoom||this.object.isOrthographicCamera)this._spherical.radius=this._clampDistance(this._spherical.radius);else{let e=this._spherical.radius;this._spherical.radius=this._clampDistance(this._spherical.radius*this._scale),i=e!=this._spherical.radius}if(Gp.setFromSpherical(this._spherical),Gp.applyQuaternion(this._quatInverse),t.copy(this.target).add(Gp),this.object.lookAt(this.target),this.enableDamping===!0?(this._sphericalDelta.theta*=1-this.dampingFactor,this._sphericalDelta.phi*=1-this.dampingFactor,this._panOffset.multiplyScalar(1-this.dampingFactor)):(this._sphericalDelta.set(0,0,0),this._panOffset.set(0,0,0)),this.zoomToCursor&&this._performCursorZoom){let e=null;if(this.object.isPerspectiveCamera){let t=Gp.length();e=this._clampDistance(t*this._scale);let n=t-e;this.object.position.addScaledVector(this._dollyDirection,n),this.object.updateMatrixWorld(),i=!!n}else if(this.object.isOrthographicCamera){let t=new H(this._mouse.x,this._mouse.y,0);t.unproject(this.object);let n=this.object.zoom;this.object.zoom=Math.max(this.minZoom,Math.min(this.maxZoom,this.object.zoom/this._scale)),this.object.updateProjectionMatrix(),i=n!==this.object.zoom;let r=new H(this._mouse.x,this._mouse.y,0);r.unproject(this.object),this.object.position.sub(r).add(t),this.object.updateMatrixWorld(),e=Gp.length()}else console.warn(`WARNING: OrbitControls.js encountered an unknown camera type - zoom to cursor disabled.`),this.zoomToCursor=!1;e!==null&&(this.screenSpacePanning?this.target.set(0,0,-1).transformDirection(this.object.matrix).multiplyScalar(e).add(this.object.position):(Hp.origin.copy(this.object.position),Hp.direction.set(0,0,-1).transformDirection(this.object.matrix),Math.abs(this.object.up.dot(Hp.direction))<Wp?this.object.lookAt(this.target):(Up.setFromNormalAndCoplanarPoint(this.object.up,this.target),Hp.intersectPlane(Up,this.target))))}else if(this.object.isOrthographicCamera){let e=this.object.zoom;this.object.zoom=Math.max(this.minZoom,Math.min(this.maxZoom,this.object.zoom/this._scale)),e!==this.object.zoom&&(this.object.updateProjectionMatrix(),i=!0)}return this._scale=1,this._performCursorZoom=!1,i||this._lastPosition.distanceToSquared(this.object.position)>Jp||8*(1-this._lastQuaternion.dot(this.object.quaternion))>Jp||this._lastTargetPosition.distanceToSquared(this.target)>Jp?(this.dispatchEvent(zp),this._lastPosition.copy(this.object.position),this._lastQuaternion.copy(this.object.quaternion),this._lastTargetPosition.copy(this.target),!0):!1}_getAutoRotationAngle(e){return e===null?Kp/60/60*this.autoRotateSpeed:Kp/60*this.autoRotateSpeed*e}_getZoomScale(e){let t=Math.abs(e*.01);return .95**(this.zoomSpeed*t)}_rotateLeft(e){this._sphericalDelta.theta-=e}_rotateUp(e){this._sphericalDelta.phi-=e}_panLeft(e,t){Gp.setFromMatrixColumn(t,0),Gp.multiplyScalar(-e),this._panOffset.add(Gp)}_panUp(e,t){this.screenSpacePanning===!0?Gp.setFromMatrixColumn(t,1):(Gp.setFromMatrixColumn(t,0),Gp.crossVectors(this.object.up,Gp)),Gp.multiplyScalar(e),this._panOffset.add(Gp)}_pan(e,t){let n=this.domElement;if(this.object.isPerspectiveCamera){let r=this.object.position;Gp.copy(r).sub(this.target);let i=Gp.length();i*=Math.tan(this.object.fov/2*Math.PI/180),this._panLeft(2*e*i/n.clientHeight,this.object.matrix),this._panUp(2*t*i/n.clientHeight,this.object.matrix)}else this.object.isOrthographicCamera?(this._panLeft(e*(this.object.right-this.object.left)/this.object.zoom/n.clientWidth,this.object.matrix),this._panUp(t*(this.object.top-this.object.bottom)/this.object.zoom/n.clientHeight,this.object.matrix)):(console.warn(`WARNING: OrbitControls.js encountered an unknown camera type - pan disabled.`),this.enablePan=!1)}_dollyOut(e){this.object.isPerspectiveCamera||this.object.isOrthographicCamera?this._scale/=e:(console.warn(`WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.`),this.enableZoom=!1)}_dollyIn(e){this.object.isPerspectiveCamera||this.object.isOrthographicCamera?this._scale*=e:(console.warn(`WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.`),this.enableZoom=!1)}_updateZoomParameters(e,t){if(!this.zoomToCursor)return;this._performCursorZoom=!0;let n=this.domElement.getBoundingClientRect(),r=e-n.left,i=t-n.top,a=n.width,o=n.height;this._mouse.x=r/a*2-1,this._mouse.y=-(i/o)*2+1,this._dollyDirection.set(this._mouse.x,this._mouse.y,1).unproject(this.object).sub(this.object.position).normalize()}_clampDistance(e){return Math.max(this.minDistance,Math.min(this.maxDistance,e))}_handleMouseDownRotate(e){this._rotateStart.set(e.clientX,e.clientY)}_handleMouseDownDolly(e){this._updateZoomParameters(e.clientX,e.clientX),this._dollyStart.set(e.clientX,e.clientY)}_handleMouseDownPan(e){this._panStart.set(e.clientX,e.clientY)}_handleMouseMoveRotate(e){this._rotateEnd.set(e.clientX,e.clientY),this._rotateDelta.subVectors(this._rotateEnd,this._rotateStart).multiplyScalar(this.rotateSpeed);let t=this.domElement;this._rotateLeft(Kp*this._rotateDelta.x/t.clientHeight),this._rotateUp(Kp*this._rotateDelta.y/t.clientHeight),this._rotateStart.copy(this._rotateEnd),this.update()}_handleMouseMoveDolly(e){this._dollyEnd.set(e.clientX,e.clientY),this._dollyDelta.subVectors(this._dollyEnd,this._dollyStart),this._dollyDelta.y>0?this._dollyOut(this._getZoomScale(this._dollyDelta.y)):this._dollyDelta.y<0&&this._dollyIn(this._getZoomScale(this._dollyDelta.y)),this._dollyStart.copy(this._dollyEnd),this.update()}_handleMouseMovePan(e){this._panEnd.set(e.clientX,e.clientY),this._panDelta.subVectors(this._panEnd,this._panStart).multiplyScalar(this.panSpeed),this._pan(this._panDelta.x,this._panDelta.y),this._panStart.copy(this._panEnd),this.update()}_handleMouseWheel(e){this._updateZoomParameters(e.clientX,e.clientY),e.deltaY<0?this._dollyIn(this._getZoomScale(e.deltaY)):e.deltaY>0&&this._dollyOut(this._getZoomScale(e.deltaY)),this.update()}_handleKeyDown(e){let t=!1;switch(e.code){case this.keys.UP:e.ctrlKey||e.metaKey||e.shiftKey?this._rotateUp(Kp*this.rotateSpeed/this.domElement.clientHeight):this._pan(0,this.keyPanSpeed),t=!0;break;case this.keys.BOTTOM:e.ctrlKey||e.metaKey||e.shiftKey?this._rotateUp(-Kp*this.rotateSpeed/this.domElement.clientHeight):this._pan(0,-this.keyPanSpeed),t=!0;break;case this.keys.LEFT:e.ctrlKey||e.metaKey||e.shiftKey?this._rotateLeft(Kp*this.rotateSpeed/this.domElement.clientHeight):this._pan(this.keyPanSpeed,0),t=!0;break;case this.keys.RIGHT:e.ctrlKey||e.metaKey||e.shiftKey?this._rotateLeft(-Kp*this.rotateSpeed/this.domElement.clientHeight):this._pan(-this.keyPanSpeed,0),t=!0}t&&(e.preventDefault(),this.update())}_handleTouchStartRotate(e){if(this._pointers.length===1)this._rotateStart.set(e.pageX,e.pageY);else{let t=this._getSecondPointerPosition(e),n=.5*(e.pageX+t.x),r=.5*(e.pageY+t.y);this._rotateStart.set(n,r)}}_handleTouchStartPan(e){if(this._pointers.length===1)this._panStart.set(e.pageX,e.pageY);else{let t=this._getSecondPointerPosition(e),n=.5*(e.pageX+t.x),r=.5*(e.pageY+t.y);this._panStart.set(n,r)}}_handleTouchStartDolly(e){let t=this._getSecondPointerPosition(e),n=e.pageX-t.x,r=e.pageY-t.y,i=Math.sqrt(n*n+r*r);this._dollyStart.set(0,i)}_handleTouchStartDollyPan(e){this.enableZoom&&this._handleTouchStartDolly(e),this.enablePan&&this._handleTouchStartPan(e)}_handleTouchStartDollyRotate(e){this.enableZoom&&this._handleTouchStartDolly(e),this.enableRotate&&this._handleTouchStartRotate(e)}_handleTouchMoveRotate(e){if(this._pointers.length==1)this._rotateEnd.set(e.pageX,e.pageY);else{let t=this._getSecondPointerPosition(e),n=.5*(e.pageX+t.x),r=.5*(e.pageY+t.y);this._rotateEnd.set(n,r)}this._rotateDelta.subVectors(this._rotateEnd,this._rotateStart).multiplyScalar(this.rotateSpeed);let t=this.domElement;this._rotateLeft(Kp*this._rotateDelta.x/t.clientHeight),this._rotateUp(Kp*this._rotateDelta.y/t.clientHeight),this._rotateStart.copy(this._rotateEnd)}_handleTouchMovePan(e){if(this._pointers.length===1)this._panEnd.set(e.pageX,e.pageY);else{let t=this._getSecondPointerPosition(e),n=.5*(e.pageX+t.x),r=.5*(e.pageY+t.y);this._panEnd.set(n,r)}this._panDelta.subVectors(this._panEnd,this._panStart).multiplyScalar(this.panSpeed),this._pan(this._panDelta.x,this._panDelta.y),this._panStart.copy(this._panEnd)}_handleTouchMoveDolly(e){let t=this._getSecondPointerPosition(e),n=e.pageX-t.x,r=e.pageY-t.y,i=Math.sqrt(n*n+r*r);this._dollyEnd.set(0,i),this._dollyDelta.set(0,(this._dollyEnd.y/this._dollyStart.y)**+this.zoomSpeed),this._dollyOut(this._dollyDelta.y),this._dollyStart.copy(this._dollyEnd);let a=(e.pageX+t.x)*.5,o=(e.pageY+t.y)*.5;this._updateZoomParameters(a,o)}_handleTouchMoveDollyPan(e){this.enableZoom&&this._handleTouchMoveDolly(e),this.enablePan&&this._handleTouchMovePan(e)}_handleTouchMoveDollyRotate(e){this.enableZoom&&this._handleTouchMoveDolly(e),this.enableRotate&&this._handleTouchMoveRotate(e)}_addPointer(e){this._pointers.push(e.pointerId)}_removePointer(e){delete this._pointerPositions[e.pointerId];for(let t=0;t<this._pointers.length;t++)if(this._pointers[t]==e.pointerId){this._pointers.splice(t,1);return}}_isTrackingPointer(e){for(let t=0;t<this._pointers.length;t++)if(this._pointers[t]==e.pointerId)return!0;return!1}_trackPointer(e){let t=this._pointerPositions[e.pointerId];t===void 0&&(t=new R,this._pointerPositions[e.pointerId]=t),t.set(e.pageX,e.pageY)}_getSecondPointerPosition(e){let t=e.pointerId===this._pointers[0]?this._pointers[1]:this._pointers[0];return this._pointerPositions[t]}_customWheelEvent(e){let t=e.deltaMode,n={clientX:e.clientX,clientY:e.clientY,deltaY:e.deltaY};switch(t){case 1:n.deltaY*=16;break;case 2:n.deltaY*=100}return e.ctrlKey&&!this._controlActive&&(n.deltaY*=10),n}};function Xp(e){this.enabled!==!1&&(this._pointers.length===0&&(this.domElement.setPointerCapture(e.pointerId),this.domElement.addEventListener(`pointermove`,this._onPointerMove),this.domElement.addEventListener(`pointerup`,this._onPointerUp)),!this._isTrackingPointer(e)&&(this._addPointer(e),e.pointerType===`touch`?this._onTouchStart(e):this._onMouseDown(e)))}function Zp(e){this.enabled!==!1&&(e.pointerType===`touch`?this._onTouchMove(e):this._onMouseMove(e))}function Qp(e){switch(this._removePointer(e),this._pointers.length){case 0:this.domElement.releasePointerCapture(e.pointerId),this.domElement.removeEventListener(`pointermove`,this._onPointerMove),this.domElement.removeEventListener(`pointerup`,this._onPointerUp),this.dispatchEvent(Vp),this.state=qp.NONE;break;case 1:let t=this._pointers[0],n=this._pointerPositions[t];this._onTouchStart({pointerId:t,pageX:n.x,pageY:n.y})}}function $p(e){let n;switch(e.button){case 0:n=this.mouseButtons.LEFT;break;case 1:n=this.mouseButtons.MIDDLE;break;case 2:n=this.mouseButtons.RIGHT;break;default:n=-1}switch(n){case t.DOLLY:if(this.enableZoom===!1)return;this._handleMouseDownDolly(e),this.state=qp.DOLLY;break;case t.ROTATE:if(e.ctrlKey||e.metaKey||e.shiftKey){if(this.enablePan===!1)return;this._handleMouseDownPan(e),this.state=qp.PAN}else{if(this.enableRotate===!1)return;this._handleMouseDownRotate(e),this.state=qp.ROTATE}break;case t.PAN:if(e.ctrlKey||e.metaKey||e.shiftKey){if(this.enableRotate===!1)return;this._handleMouseDownRotate(e),this.state=qp.ROTATE}else{if(this.enablePan===!1)return;this._handleMouseDownPan(e),this.state=qp.PAN}break;default:this.state=qp.NONE}this.state!==qp.NONE&&this.dispatchEvent(Bp)}function em(e){switch(this.state){case qp.ROTATE:if(this.enableRotate===!1)return;this._handleMouseMoveRotate(e);break;case qp.DOLLY:if(this.enableZoom===!1)return;this._handleMouseMoveDolly(e);break;case qp.PAN:if(this.enablePan===!1)return;this._handleMouseMovePan(e)}}function tm(e){this.enabled!==!1&&this.enableZoom!==!1&&this.state===qp.NONE&&(e.preventDefault(),this.dispatchEvent(Bp),this._handleMouseWheel(this._customWheelEvent(e)),this.dispatchEvent(Vp))}function nm(e){this.enabled!==!1&&this.enablePan!==!1&&this._handleKeyDown(e)}function rm(e){switch(this._trackPointer(e),this._pointers.length){case 1:switch(this.touches.ONE){case n.ROTATE:if(this.enableRotate===!1)return;this._handleTouchStartRotate(e),this.state=qp.TOUCH_ROTATE;break;case n.PAN:if(this.enablePan===!1)return;this._handleTouchStartPan(e),this.state=qp.TOUCH_PAN;break;default:this.state=qp.NONE}break;case 2:switch(this.touches.TWO){case n.DOLLY_PAN:if(this.enableZoom===!1&&this.enablePan===!1)return;this._handleTouchStartDollyPan(e),this.state=qp.TOUCH_DOLLY_PAN;break;case n.DOLLY_ROTATE:if(this.enableZoom===!1&&this.enableRotate===!1)return;this._handleTouchStartDollyRotate(e),this.state=qp.TOUCH_DOLLY_ROTATE;break;default:this.state=qp.NONE}break;default:this.state=qp.NONE}this.state!==qp.NONE&&this.dispatchEvent(Bp)}function im(e){switch(this._trackPointer(e),this.state){case qp.TOUCH_ROTATE:if(this.enableRotate===!1)return;this._handleTouchMoveRotate(e),this.update();break;case qp.TOUCH_PAN:if(this.enablePan===!1)return;this._handleTouchMovePan(e),this.update();break;case qp.TOUCH_DOLLY_PAN:if(this.enableZoom===!1&&this.enablePan===!1)return;this._handleTouchMoveDollyPan(e),this.update();break;case qp.TOUCH_DOLLY_ROTATE:if(this.enableZoom===!1&&this.enableRotate===!1)return;this._handleTouchMoveDollyRotate(e),this.update();break;default:this.state=qp.NONE}}function am(e){this.enabled!==!1&&e.preventDefault()}function om(e){e.key===`Control`&&(this._controlActive=!0,this.domElement.getRootNode().addEventListener(`keyup`,this._interceptControlUp,{passive:!0,capture:!0}))}function sm(e){e.key===`Control`&&(this._controlActive=!1,this.domElement.getRootNode().removeEventListener(`keyup`,this._interceptControlUp,{passive:!0,capture:!0}))}function cm(){let e=new Ur(new ol(20,96).rotateX(-Math.PI/2),new ul({color:7234135}));return e.position.y=-.002,e.visible=!1,e}function lm(){let e=new ys,t=new ul({color:7234135}),n=(n,r,i,a,o,s,c=0)=>{let l=new Ur(new Kr(n,r,i),t);l.position.set(a,o,s),l.rotation.x=c,e.add(l)};for(let e=0;e<6;e++)n(3.5,.15*(e+1),.5,1.75,.15*(e+1)/2,1.75+.5*e);let r=.6;return n(3.5,.1,Math.hypot(r,3),-1.75,r/2-.05,3,-Math.atan2(r,3)),n(7,1,.3,0,.5,5.5),n(.3,.1,1.2,.8,.05,.2),n(.3,.1,1.2,-.8,.05,.2),e.visible=!1,e}function um(){let e=new ys,t=new ul({color:10134704}),n=(n,r,i,a=0,o=0)=>{let s=new Ur(n,t);s.position.set(r,i,a),s.rotation.z=o,e.add(s)};n(new ll(.11,16,12),0,1.58),n(new cl(.035,.1,8).rotateX(Math.PI/2),0,1.58,.13),n(new Kr(.1,.05,.2),.1,.03,.06),n(new Kr(.1,.05,.2),-.1,.03,.06),n(new sl(.045,.05,.08),0,1.44),n(new al(.16,.36,4,12),0,1.15),n(new al(.14,.08,4,12),0,.88);for(let e of[-1,1])n(new al(.06,.62,4,8),.1*e,.42),n(new al(.045,.52,4,8),.27*e,1.08,0,.12*e);return e}var dm={1:[0,1.58,.08],3:[.3,.85,.1],4:[.3,1.2,.1],5:[.3,1.6,.1],6:[-.2,1.42,0],7:[.2,1.42,0],8:[-.3,1.05,0],9:[.3,1.05,0],10:[-.1,.3,0],11:[.1,.3,0],25:[0,1.72,0],26:[0,1.6,0],27:[0,1.6,.12],28:[0,1.3,.05],30:[0,1,0],31:[0,.95,0],32:[-.33,.78,0],33:[.33,.78,0],34:[-.1,.03,.05],35:[.1,.03,.05],43:[-.04,1.6,.1],44:[.04,1.6,.1],77:[-.33,.78,0],78:[.33,.78,0],16:[0,1.28,.75],29:[0,1.045,.04],42:[0,1.765,0],45:[0,1.865,0],46:[0,1.045,0],47:[0,1.077,0],48:[0,.962,0],49:[0,1.325,0],50:[0,.955,0],51:[0,1.638,0],52:[0,1.295,.214],53:[0,1.514,.136],54:[0,1.127,.208],55:[0,.947,.222],62:[0,1.5,-.414],63:[0,1.05,0],64:[0,1.35,0],66:[0,1.17,-.3],67:[0,.68,.15],68:[0,1.018,0],70:[0,1.646,0],71:[0,0,0],76:[0,1.564,0],81:[0,1.454,0],97:[0,2.214,0],98:[0,1.945,0]};function fm(e){let t=e.children.filter(e=>e instanceof Ur),n={geometry:Lp(t.map(e=>(e.updateMatrix(),e.geometry.clone().applyMatrix4(e.matrix)))),object:e,meshes:t},r=new Map;for(let[t,[n,i,a]]of Object.entries(dm)){let o=new Yn;o.name=`bind point ${t}`,o.position.set(n,i,a),e.add(o),r.set(Number(t),o)}return{object:e,bindPoints:r,skin:n,dissolve:!0}}function pm(e,t){Mp(),Gf();let n=new As({canvas:e,antialias:!0});n.setPixelRatio(devicePixelRatio);let r=new js;r.background=new W(1974050);let i=new $l(10,10,5592405,3355443),a=new eu(1);r.add(i,a),r.add(new El(16777215,4210752,1.2));let o=new Ll(16777215,1.5);o.position.set(3,5,2),r.add(o);let s=cm();r.add(s);let c=lm();r.add(c);let l=um();l.visible=!1,r.add(l);let u=um();u.position.set(0,0,6),u.rotation.y=Math.PI,u.visible=!1,r.add(u);let d=()=>({motion:`still`,amp:2,period:4,jump:!1,jumpHeight:1,jumpPeriod:2}),f={distance:6,side:0,face:!0,caster:d(),target:d(),time:0,pose:``,poseFrame:0,posePlay:!1},p=null;function m(e,t,n){let r=2*Math.PI*t/Math.max(.1,e.period);if(n.set(0,0,0),e.motion===`strafe`?n.x=e.amp*Math.sin(r):e.motion===`forward`?n.z=e.amp*Math.sin(r):e.motion===`circle`?n.set(e.amp*Math.sin(r),0,e.amp*(Math.cos(r)-1)):e.motion===`dash`&&(n.x=Math.floor(t/Math.max(.1,e.period))%2?e.amp:0),e.jump){let r=Math.min(.7,e.jumpPeriod),i=t%e.jumpPeriod/r;i<1&&(n.y=4*e.jumpHeight*i*(1-i))}return n}let h=new H,g=new H;function _(){l.position.copy(m(f.caster,f.time,h)),u.position.set(f.side,0,f.distance).add(m(f.target,f.time,g));let e=u.position.x-l.position.x,t=u.position.z-l.position.z;l.rotation.y=f.face?Math.atan2(e,t):0,u.rotation.y=f.face?Math.atan2(-e,-t):Math.PI,p?.pose(f.pose,f.posePlay?f.time:f.poseFrame/30),l.updateMatrixWorld(!0),u.updateMatrixWorld(!0)}_();let v=fm(l),y=v,b=new Set,x=new ys;x.visible=!1,r.add(x);function S(e,t){let n=document.createElement(`canvas`);n.width=64,n.height=32;let r=n.getContext(`2d`);r.font=`bold 22px ui-monospace, monospace`,r.fillStyle=t,r.textAlign=`center`,r.textBaseline=`middle`,r.fillText(e,32,16);let i=new Ys(new Fs({map:new Oc(n),depthTest:!1,transparent:!0}));return i.scale.set(.12,.06,1),i.renderOrder=1e9,i}function C(e){b=e;for(let e of[...x.children])e.removeFromParent();for(let[t,n]of y.bindPoints){let r=e.has(t),i=r?`#ffd166`:`#8a8f98`,a=new ys,o=new eu(r?.08:.04);o.material.depthTest=!1,o.renderOrder=1e9;let s=S(String(t),i);s.position.set(0,.06,0),s.material.opacity=r?1:.6,a.add(o,s),a.userData.anchor=n,x.add(a)}}let w=new ai(45,1,.01,1e3);w.position.set(3,2.5,4);let T=new Yp(w,e);T.target.set(0,1,0);function E(){let{clientWidth:t,clientHeight:r}=e.parentElement;n.setSize(t,r,!1),w.aspect=t/Math.max(r,1),w.updateProjectionMatrix()}new ResizeObserver(E).observe(e.parentElement);let D=null,O=1,k=new Rl,ee=new Ip,A=null,te=e=>new Promise(t=>A=n=>t(e(n)));n.setAnimationLoop(()=>{let i=Math.min(k.getDelta(),.1)*O;if(T.update(),(!D||D.playing)&&(f.time+=i),_(),ee.beforeRender(n,r,w,i),D&&t(D),x.visible)for(let e of x.children)e.userData.anchor.getWorldPosition(e.position);if(n.render(r,w),ee.afterRender(n),A){let t=A;A=null,t(e)}});function ne(e){D&&(ee.remove(D),D.dispose(),D.removeFromParent()),D=e,D&&(r.add(D),ee.add(D),D.setCaster(y),D.target=D.schema.binders.some(e=>e.goal&&(e.type===1||e.type===2||e.type===4))?u:null,C(new Set(D.schema.binders.filter(e=>e.bindTargetPoint===bd.ByName&&e.bindPointId>=0).map(e=>e.bindPointId))),D.restart(j))}let j=1;function M(e){if(!D)return null;e=Math.max(0,Math.round(e));let t=Math.round(D.time),n=e>=t?t:0;n===0?(D.restart(j),f.time=0):D.play();for(let t=n;t<e;t++)for(let e=0;e<2;e++)f.time+=.5/D.fps,_(),D.update(.5/D.fps,w);return D.pause(),e}function N(e){p?.root.removeFromParent(),p=e;for(let t of l.children)t instanceof Ur&&(t.visible=!e);e&&l.add(e.root),y=e?e.character:v,_(),D&&(D.setCaster(y),D.restart(j)),C(b)}return{renderer:n,scene:r,camera:w,controls:T,grid:i,axes:a,floor:s,relief:c,human:l,targetDummy:u,bindMarkers:x,system:ee,character:v,stage:f,get effect(){return D},get speed(){return O},set speed(e){O=e},get seed(){return j},set seed(e){j=e},setEffect:ne,setCharacterModel:N,seek:M,captureFrame:te}}var mm=1,hm=`3a682ba`;function gm(e,t){let n=new Set,r=e=>{for(let t of n)t(e)},i=e=>{throw r({type:`error`,message:String(e),stack:e instanceof Error?e.stack:void 0}),e},a=typeof t.files==`string`?new Eu(t.files):t.files,o={load:async e=>{let t=await a.load(e);return t||r({type:`missing`,path:e}),t},forget:e=>a.forget?.(e)},s=``,c=0,l=pm(e,e=>{let t=e.stats,n={type:`frame`,frame:t.frame,playing:e.playing,finished:e.finished,emitters:t.emitters,particles:t.particles},i=JSON.stringify(n);i!==s&&(s=i,r(n)),e.warnings.size!==c&&(c=e.warnings.size,r({type:`warnings`,warnings:[...e.warnings]}))}),{renderer:u,scene:d,camera:f,controls:p}=l,m=()=>({position:f.position.toArray(),target:p.target.toArray(),fov:f.fov});p.addEventListener(`end`,()=>r({type:`camera`,...m()})),e.addEventListener(`webglcontextlost`,()=>r({type:`error`,message:`webglcontextlost`})),queueMicrotask(()=>r({type:`ready`,protocol:1,build:hm}));let h=new Fp(o),g=``,_=null,v=!1,y=0,b=!1,x=!1,S={particles:[],emitters:[],effectors:[],timelines:[]},C=0;function w(e){let t=[[e.hiddenParticles,S.particles],[e.hiddenEmitters,S.emitters],[e.hiddenEffectors,S.effectors],[e.hiddenTimelines,S.timelines]];for(let[e,n]of t){e.clear();for(let t of n)e.add(t)}}let T=async e=>{if(typeof e!=`string`)return e;let t=await fetch(e);if(!t.ok)throw Error(`${e}: ${t.status}`);return new Uint8Array(await t.arrayBuffer())};async function E(e,t){let n=++C,r=l.effect,i=t&&r?Math.round(r.time):0,a=t&&r?r.playing:!0,o=bu(e,g),u=await h.create(o,{loop:v});return n===C?(_=e,u.loopDelay=y,t&&r&&(u.scenario=r.scenario),l.setEffect(u),u.debug.wireframe=b,u.debug.emitters=x,w(u),c=0,s=``,i>0&&l.seek(i),a?u.play():u.pause(),u):(u.dispose(),null)}async function D(e){if(!e)return null;let t=await nd(e.doc,o);return r({type:`loaded`,key:g,report:t,warnings:[...e.warnings]}),t}return{on(e){return n.add(e),()=>n.delete(e)},async open(e,t){try{let n=await T(e);return g=t??(typeof e==`string`?e:``),h.dispose(),h=new Fp(o),await D(await E(n,!1))}catch(e){return i(e)}},async reload(e){try{return await D(await E(await T(e),!0))}catch(e){return i(e)}},async invalidate(e){try{h.forget(e),_&&await E(_,!0)}catch(e){i(e)}},play(){l.effect?.play()},pause(){l.effect?.pause()},restart(){l.effect?.restart(l.seed),l.stage.time=0},seek(e){return l.seek(e)},setSpeed(e){l.speed=Math.min(2,Math.max(0,e))},trigger(e){return l.effect?.trigger(e)??!1},release(){l.effect?.release()},playScenario(e){let t=l.effect;return t?(t.playScenario(e,l.seed),l.stage.time=0,!0):!1},playTimeline(e,t=!1){let n=l.effect;return n?t?n.playTimelineAlone(e):n.playTimeline(e):!1},setStage(e){let t=l.stage;e.showCaster!==void 0&&(l.human.visible=e.showCaster),e.showTarget!==void 0&&(l.targetDummy.visible=e.showTarget),e.distance!==void 0&&(t.distance=e.distance),e.side!==void 0&&(t.side=e.side),e.face!==void 0&&(t.face=e.face),e.casterMotion&&Object.assign(t.caster,e.casterMotion),e.targetMotion&&Object.assign(t.target,e.targetMotion),e.bindMarkers!==void 0&&(l.bindMarkers.visible=e.bindMarkers),e.resetClock&&(t.time=0)},setHidden(e){S.particles=e.particles??[],S.emitters=e.emitters??[],S.effectors=e.effectors??[],S.timelines=e.timelines??[],l.effect&&w(l.effect)},setView(e){e.toneMapping!==void 0&&(u.toneMapping=e.toneMapping?5:0),e.exposure!==void 0&&(u.toneMappingExposure=2**e.exposure),e.lightIntensity!==void 0&&(jp.lightIntensity=e.lightIntensity),e.background!==void 0&&(d.background=new W(e.background)),e.floor!==void 0&&(l.floor.visible=e.floor),e.relief!==void 0&&(l.relief.visible=e.relief),e.grid!==void 0&&(l.grid.visible=l.axes.visible=e.grid),e.loop!==void 0&&(v=e.loop,l.effect&&(l.effect.loop=v)),e.loopDelay!==void 0&&(y=Math.max(0,e.loopDelay),l.effect&&(l.effect.loopDelay=y)),e.wireframe!==void 0&&(b=e.wireframe,l.effect&&(l.effect.debug.wireframe=b)),e.emitters!==void 0&&(x=e.emitters,l.effect&&(l.effect.debug.emitters=x))},setCamera(e){e.position&&f.position.fromArray(e.position),e.target&&p.target.fromArray(e.target),e.fov!==void 0&&(f.fov=e.fov,f.updateProjectionMatrix()),p.update()},getCamera:m,snapshot(e){return l.captureFrame(t=>{if(!e||e>=t.width)return t.toDataURL(`image/png`);let n=document.createElement(`canvas`);return n.width=e,n.height=Math.round(t.height*e/t.width),n.getContext(`2d`).drawImage(t,0,0,n.width,n.height),n.toDataURL(`image/png`)})},get effect(){return l.effect},stage:l}}return e.BUILD=hm,e.PROTOCOL=mm,e.create=gm,e})({});