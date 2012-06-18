(function() {

  cloneextend = {}

  this.cloneextend = cloneextend

  cloneextend.replace = function replace(a, b)
  {
   if (!b)
   {
    return a;
   }
   var key;
   for (key in b)
   {
    if(b.hasOwnProperty(key))
    {
     a[key] = b[key];
    }
   }

   return a;
  };

  function add(a, b)
  {
   if (!b)
   {
    return a;
   }
   var key;
   for (key in b)
   {
    if(b.hasOwnProperty(key))
    {
     if(typeof a[key] === 'undefined' ||  a[key]===null)
     {
      a[key] = b[key];
     }
    }
   }
   return a;
  };


  cloneextend.extend = function extend(a, b, context, newobjs, aparent, aname, haveaparent) // context is anti circular references mechanism
  {
   if (a==b){ return a;}
   if (!b)  { return a;}

   var key, clean_context=false, return_sublevel=false,b_pos;
   if(!haveaparent){ aparent={'a':a}; aname='a'; }
   if(!context){clean_context=true;context=[];newobjs=[];}
   b_pos=context.indexOf(b);
   if( b_pos==-1 ) {context.push(b);newobjs.push([aparent, aname]);} else { return newobjs[b_pos][0][ newobjs[b_pos][1] ]; }

   for (key in b)
   {
     if(b.hasOwnProperty(key))
     {
     if(typeof a[key] === 'undefined')
     {
      if(typeof b[key] === 'object')
      {
       if( b[key] instanceof Array ) // http://javascript.crockford.com/remedial.html
        {a[key] = cloneextend.extend([], b[key],context,newobjs,a,key,true);}
       else if(b[key]===null)
        {a[key] = null;}
       else if( b[key] instanceof Date )
        { a[key]= new b[key].constructor();a[key].setTime(b[key].getTime());  }
       else
        { a[key] = cloneextend.extend({}, b[key],context,newobjs,a,key,true); /*a[key].constructor = b[key].constructor;  a[key].prototype = b[key].prototype;*/ }
      }
      else
      {  a[key] = b[key]; }
     }
     else if(typeof a[key] === 'object' && a[key] !== null)
     {  a[key] = cloneextend.extend(a[key], b[key],context,newobjs,a,key,true); /*a[key].constructor = b[key].constructor;  a[key].prototype = b[key].prototype;*/ }
     else
     {  a[key] = b[key]; }
    }
   }
   if(clean_context) {context=null;newobjs=null;}
   if(!haveaparent)
   {
    aparent=null;
    return a;
   }
   if(typeof a === 'object' && !(a instanceof Array) )
   {
    /*a.constructor = b.constructor;
    a.prototype   = b.prototype*/;
   }
   return a;
  };

  cloneextend.extenduptolevel = function extenduptolevel(a, b, levels, context, newobjs, aparent, aname, haveaparent)
  {
   if (a==b){ return a;}
   if (!b){ return a;}

   var key, clean_context=false, return_sublevel=false;
   if(!haveaparent){ aparent={'a':a}; aname='a'; }
   if(!context){clean_context=true;context=[];newobjs=[];}
   b_pos=context.indexOf(b);
   if( b_pos==-1 ) {context.push(b);newobjs.push([aparent, aname]);} else { return newobjs[b_pos][0][ newobjs[b_pos][1] ]; }

   for (key in b)
   {
    if(b.hasOwnProperty(key))
    {
     if(typeof a[key] === 'undefined')
     {
      if(typeof b[key] === 'object' && levels>0)
      {
       if( b[key] instanceof Array ) // http://javascript.crockford.com/remedial.html
       { a[key] = cloneextend.extenduptolevel([], b[key],levels-1,context,newobjs,a,key,true); }
       else if(b[key]===null)
       { a[key] = null; }
       else if( b[key] instanceof Date )
       { a[key]= new b[key].constructor();a[key].setTime(b[key].getTime());  }
       else
       { a[key] = cloneextend.extenduptolevel({}, b[key],levels-1,context,newobjs,a,key,true); }
      }
      else
      {  a[key] = b[key]; }
     }
     else if(typeof a[key] === 'object' && a[key] !== null && levels>0)
     {  a[key] = cloneextend.extenduptolevel(a[key], b[key],levels-1,context,newobjs,a,key,true); }
     else
     {  a[key] = b[key]; }
    }
   }
   if(clean_context) {context=null;newobjs=null;}

   if(!haveaparent)
   {
    aparent=null;
    return a;
   }
   if(typeof a === 'object' && !(a instanceof Array) )
   {
    /*a.constructor = b.constructor;
    a.prototype   = b.prototype;*/
   }
   return a;
  };

  cloneextend.clone = function clone(obj)
  {
   if (typeof obj === 'object')
   {
    if (obj ===null ) { return null; }
    if (obj instanceof Array )
    { return cloneextend.extend([], obj); }
    else if( obj instanceof Date )
    {
     var t= new obj.constructor();
     t.setTime(obj.getTime());
     return t;
    }
    else
    { return cloneextend.extend({}, obj); }
   }
   return obj;
  };

  cloneextend.cloneextend = function cloneextend(obj,exteddata)
  {
   if (typeof obj === 'object')
   {
    if (obj ===null ) { return null; }
    return cloneextend.extend(clone(obj),exteddata);
   }
   return obj;
  };


  cloneextend.cloneuptolevel = function cloneuptolevel(obj,level) // clone only numlevels levels other levels leave references
  {
   if (typeof obj === 'object')
   {
    if (obj ===null ) { return null; }
    if (obj instanceof Array ) { return cloneextend.extenduptolevel([], obj,level); }
    return cloneextend.extenduptolevel({}, obj,level);
   }
   return obj;
  };

  cloneextend.foreach = function foreach(object, block, context)
  {
   if (object)
   {
    if (typeof object === "object" && object instanceof Array)
     return object.forEach(object, block, context)
    else //if (typeof object === "object") // or (object instanceof Function)...
    {
     if(object)
     for (var key in object)
     {
      if(object.hasOwnProperty(key))
      {
       if(block.call(context, object[key], key, object)===false)break;
      }
     }
    }
   }
  };

}).call(this);