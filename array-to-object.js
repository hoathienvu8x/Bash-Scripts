// Reduce array of objects to an object in JavaScript
// https://www.amitmerchant.com/reduce-array-of-objects-to-an-object-in-javascript
/**
 * The other day when working with one of the applications, I needed to convert/reduce
 * an array of objects to an object.
 *
 * Here’s the array that I wanted to reduce.
 *
 *```
 * const ethnicities = [
 *   {
 *      id: 1,
 *      name: 'Asian'
 *   },
 *   {
 *     id: 2,
 *     name: 'African'
 *   },
 *   {
 *     id: 3,
 *     name: 'Caucasian'
 *   }
 * ]
 *```
 
 * use `Object.fromEntries()`, like this:
 * const ethnicities = [
 *    {id: 1, name: 'Asian'},
 *    {id: 2, name: 'African'},
 *   {id: 3, name: 'Caucasian'},
 * ];

 * const ethnicitiesObject = Object.fromEntries(
 *    ethnicities.map(({id, name}) => [id, name])
 * );

 * console.log(ethnicitiesObject);
 * // { 1: 'Asian', 2: 'African', 3: 'Caucasian' }
 * Object.fromEntries() is less known, but very handy too.
 */
s=''
Object.fromEntries(s.split('&').map(function(v) {
  return v.split('=').map(function(v){
    return decodeURIComponent(v);
  });
})
